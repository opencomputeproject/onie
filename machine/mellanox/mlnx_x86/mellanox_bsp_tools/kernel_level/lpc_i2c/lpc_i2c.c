/*
 *
 * Copyright (C) Mellanox Technologies Ltd. 2001-2014.  ALL RIGHTS RESERVED.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 *
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/delay.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <asm/irq.h>
#include <linux/ioport.h>
#include <asm/io.h>
#include <linux/fs.h>
#include <linux/i2c.h>
#include <linux/pci.h>
#include <linux/platform_device.h>

#include "lpc_i2c.h"


#define LPCI2C_MOD_DESCRIPTION    "x86 LPC - I2C bridge driver. Build:" " "__DATE__" "__TIME__
#define LPCI2C_MOD_VERSION       "1.0.0"


static int dbg_lvl = LPCI2C_DFLT_DBG_LVL;
module_param(dbg_lvl, int, 0644);

static bool force_irq;
module_param(force_irq, bool, 0);

static bool i2c_400khz;
module_param(i2c_400khz, bool, 0);

static int block_sz = LPCI2C_DATA_REG_SZ;
module_param(block_sz, int, 0644);

static int retr_num = LPCI2C_RETR_NUM;
module_param(retr_num, int, 0644);

static int xfer_to = LPCI2C_XFER_TO;
module_param(xfer_to, int, 0644);

static int poll_time = LPCI2C_POLL_TIME;
module_param(poll_time, int, 0644);

struct platform_device* lpci2c_plat_dev = NULL;

static struct resource lpc_resources[] = {
    {
        .start = LPC_CPLD_I2C_BASE_ADRR,
        .end = LPC_CPLD_I2C_BASE_ADRR + LPC_CPLD_IO_LEN,
        .name = "cpld_lpc_i2c",
        .flags = IORESOURCE_IO,
    },
    {
        .start = LPC_CPLD_BASE_ADRR,
        .end = LPC_CPLD_BASE_ADRR + LPC_CPLD_IO_LEN,
        .name = "cpld_lpc",
        .flags = IORESOURCE_IO,
    }
};

static inline u8 lpci2c_read(struct lpci2c_priv* priv, u8 addr)
{
    u8 rc;

    rc = inb(priv->base_addr + addr);
    LPCI2C_LOG_DBG(5, "LPC read 0x%x = 0x%x\n", priv->base_addr + addr, rc);
    return rc;
}

static inline void lpci2c_write(struct lpci2c_priv* priv, u8 addr, u8 val)
{
	outb(val, priv->base_addr + addr);
    LPCI2C_LOG_DBG(5, "LPC write 0x%x = 0x%x\n", priv->base_addr + addr, val);
}

static void lpci2c_read_comm(struct lpci2c_priv* priv, u8 offs, u8* data, u8 len)
{
    u32 i, addr;
	u8 rem = 0, widx = 0;

    addr = priv->base_addr + offs;
    switch (len) {
    case 1:
        *((u8*)data) = inb(addr);
        break;
    case 2:
        *((u16*)data) = inw(addr);
        break;
    case 3:
        *((u16*)data) = inw(addr);
        *((u8*)(data + 2)) = inb(addr+2);
        break;
    case 4:
        *((u32*)data) = inl(addr);
        break;
    default:
        rem = len % 4;
        widx = len / 4;
        for (i = 0; i < widx; i++) 
            *((u32*)data + i) = inl(addr + i*4);
        for (i = 0; i < rem; i++) 
            *((u8*)data + widx*4 + i) = inb(addr + widx*4 + i);
        break;
    }
}

static void lpci2c_write_comm(struct lpci2c_priv* priv, u8 offs, u8* data, u8 len)
{
    u32 i, addr;
	u8 rem = 0, widx = 0;

    addr = priv->base_addr + offs;
    switch (len) {
    case 1:
        outb(*((u8*)data), addr);
        break;
    case 2:
        outw(*((u16*)data), addr);
        break;
    case 3:
        outw(*((u16*)data), addr);
        outb(*((u8*)data + 2), addr + 2);
        break;
    case 4:
        outl(*((u32*)data), addr);
        break;
    default:
        rem = len % 4;
        widx = len / 4;
        for (i = 0; i < widx; i++)
            outl(*((u32*)data + i), addr + i*4);
        for (i = 0; i < rem; i++)
            outb(*((u8*)data + widx*4 + i), addr + widx*4 + i);
        break;
    }
}
void mlnx_rw_lpc(struct lpc_rw_msg *msg)
{
    int i;
	u32 addr;
	u8 rem = 0, widx = 0;

	addr = msg->base + msg->offset;
	if (msg->read_write == 0) {
		switch (msg->datalen) {
		case 1:
			outb(*((u8*)msg->data), addr);
			break;
		case 2:
			outw(*((u16*)msg->data), addr);
			break;
		case 3:
			outw(*((u16*)msg->data), addr);
			outb(*((u8*)msg->data + 2), addr + 2);
			break;
		case 4:
			outl(*((u32*)msg->data), addr);
			break;
		default:
			rem = msg->datalen % 4;
			widx = msg->datalen / 4;
			for (i = 0; i < widx; i++)
				outl(*((u32*)msg->data + i), addr + i*4);
			for (i = 0; i < rem; i++)
				outb(*((u8*)msg->data + widx*4 + i), addr + widx*4 + i);
			break;
		}
	}
	else {
		switch (msg->datalen) {
		case 1:
			*((u8*)msg->data) = inb(addr);
			break;
		case 2:
			*((u16*)msg->data) = inw(addr);
		break;
		case 3:
            *((u16*)msg->data) = inw(addr);
            *((u8*)(msg->data + 2)) = inb(addr+2);
			break;
		case 4:
            *((u32*)msg->data) = inl(addr);
			break;
		default:		
			rem = msg->datalen % 4;
			widx = msg->datalen / 4;
            for (i = 0; i < widx; i++) 
                *((u32*)msg->data + i) = inl(addr + i*4);
            for (i = 0; i < rem; i++) 
                *(msg->data + widx*4 + i) = inb(addr + widx*4 + i);
			break;
		}
	}
}
EXPORT_SYMBOL_GPL(mlnx_rw_lpc);

/*
void mlnx_rw_lpc_kernel(struct lpc_rw_msg *msg)
{
	u32 i, addr;
	u8 rem = 0, widx = 0;

	addr = msg->base + msg->offset;
	if (msg->read_write == WRITE) {
		switch (msg->datalen) {
        case 1:
			outb(*((u8*)msg->data), addr);
			break;
        case 2:
			outw(*((u16*)msg->data), addr);
			break;
        case 3:
			outw(*((u16*)msg->data), addr);
			outb(*((u8*)msg->data + 2), addr + 2);
			break;
		case 4:
			outl(*((u32*)msg->data), addr);
			break;
		default:
			rem = msg->datalen % 4;
			widx = msg->datalen / 4;
            for (i = 0; i < widx; i++)
				outl(*((u32*)msg->data + i), addr + i*4);
			for (i = 0; i < rem; i++)
				outb(*((u8*)msg->data + widx*4 + i), addr + widx*4 + i);
			break;
		}
	}	
	else {
		switch (msg->datalen) {
        case 1:
			*((u8*)msg->data) = inb(addr);
			break;
        case 2:
			*((u16*)msg->data) = inw(addr);
			break;
        case 3:
			*((u16*)msg->data) = inw(addr);
			*((u8*)(msg->data + 2)) = inb(addr+2);
			break;
		case 4:
			*((u32*)msg->data) = inl(addr);
			break;
		default:
			rem = msg->datalen % 4;
			widx = msg->datalen / 4;
            for (i = 0; i < widx; i++) 
                *((u32*)msg->data + i) = inl(addr + i*4);
            for (i = 0; i < rem; i++) 
                *((u8*)msg->data + widx*4 + i) = inb(addr + widx*4 + i);
			break;
		}
	}
}  

static void lpci2c_rw_comm(struct lpci2c_priv* priv, u8 addr, u8* buf, u8 len, u8 rw)
{
    struct mlnx_lpc_kernel_params params;

    params.base = priv->base_addr;
    params.offset = addr;
    params.read_write = rw;
    params.datalen = len;
    params.data = buf;

    mlnx_rw_lpc_kernel(&params);
} 
*/ 

static inline int lpci2c_invalid_addr(const struct i2c_msg* msg)
{
	return (msg->addr > 0x7f);
}

static inline int lpci2c_address_neq(const struct i2c_msg* msg1, const struct i2c_msg* msg2)
{
	return (msg1->addr != msg2->addr);
}

static inline int lpci2c_invalid_flag(const struct i2c_msg* msg)
{
    if (msg->flags != 0)
        if ((msg->flags && LPCI2C_VALID_FLAG) != msg->flags)
            return LPCI2C_RC_FAILURE;
    return LPCI2C_RC_OK;
}

static inline int lpci2c_invalid_buf(const struct i2c_msg* msg)
{
	return (!(msg->buf));
}

/* Check validity of current i2c message and all transfer.
   Calculate also coomon length of all i2c messages in transfer. */
static inline int lpci2c_invalid_len(const struct i2c_msg* msg, u8* comm_len)
{
    u8 max_len = ((msg->flags == I2C_M_RD) ? (block_sz - LPCI2C_MAX_ADDR_LEN) \
                   : block_sz);

    if (msg->len < 0)
        return -EINVAL;
    else if (msg->len > max_len) 
        return -EINVAL;
    else {
        *comm_len = msg->len + *comm_len;
        if (*comm_len > block_sz)
            return -EINVAL;
        else 
            return LPCI2C_RC_OK;
    }
}

/* Check validity of received i2c messages parameters.
   Returns 0 if Ok, other - in case of invalid paramters or common length of data
        that should be passed to CPLD */
static int lpci2c_check_msg_params(struct lpci2c_priv* priv, struct i2c_msg *msgs, int num, u8* comm_len)
{
    int i, j;

    if (!num) {
        LPCI2C_LOG_ERROR("Incorrect 0 num of messages\n");
		return -EINVAL;
    }

    if (unlikely(lpci2c_invalid_addr(&msgs[0]))) {
		LPCI2C_LOG_ERROR("Invalid address 0x%03x\n", msgs[0].addr);
		return -EINVAL;
	}

	for (i = 0; i < num; ++i) {
        if (unlikely(lpci2c_invalid_buf(&msgs[i]))){
			LPCI2C_LOG_ERROR("Invalid buf in msg[%d]\n", i);
			return -EINVAL;
		}
        if (unlikely(lpci2c_invalid_flag(&msgs[i]))) {
            LPCI2C_LOG_ERROR("Invalid flag 0x%x in msg %d\n", msgs[i].flags, i);
            return -EINVAL;
        }
		if (unlikely(lpci2c_address_neq(&msgs[0], &msgs[i]))) {
			LPCI2C_LOG_ERROR("Invalid addr in msg[%d]\n", i);
			return -EINVAL;
		}
        if (unlikely(lpci2c_invalid_len(&msgs[i], comm_len))) {
			LPCI2C_LOG_ERROR("Invalid len %d in msg[%d], addr 0x%x, flag %u\n", msgs[i].len, i, msgs[i].addr, msgs[i].flags);
			return -EINVAL;
		}
        LPCI2C_LOG_DBG(4, "Msg %d, Addr 0x%x, flag %u, msg_len %d, comm_len %u\n", i, msgs[i].addr, msgs[i].flags, msgs[i].len, *comm_len);
	}

#ifdef  LPCI2C_DEBUG
    if (dbg_lvl > 3) {
        for (i = 0; i < num; i++) {
            if ((msgs[i].flags & I2C_M_RD) != I2C_M_RD) {
                LPCI2C_LOG_DBG(5, "Msg for send %d:\n\t", i);
                for (j = 0; j < msgs[i].len; j++)
                    printk("%02x ", *(msgs[i].buf+j));
                printk("\n");
            }
        }
    }
#endif

    return LPCI2C_RC_OK;
}

/* Check if transfer is completed and status of operation.
   Returns 0 - transfer completed (both ACK or NACK),
   negative - transfer isn't finished. */
static inline int lpci2c_check_status(struct lpci2c_priv* priv, int* status)
{
    u8 val;

    val = lpci2c_read(priv, LPCI2C_STATUS_REG);

    if ((val & LPCI2C_TRANS_END)){
        if ((val & LPCI2C_STATUS_NACK))
/* The slave is unable to accept the data. No such slave, command not understood, or unable to accept any more data. */
            *status = LPCI2C_NACK_IND;
        else
            *status = LPCI2C_ACK_IND;
        return LPCI2C_RC_OK;
    } else {
        *status = LPCI2C_NO_IND;
        return LPCI2C_RC_FAILURE;
    }
    /* ToDo Add LPCI2C_ERR_IND when CPLD will support it */
}

static void lpci2c_set_transf_data(struct lpci2c_priv* priv, struct i2c_msg *msgs, int num, u8 comm_len)
{
    priv->xfer.msg = msgs;
    priv->xfer.msg_num = num;

    /* All upper layers currently are never use transfer with with more than
       2 messages. Actually, it's also not so relevant in Mellanox systems
       because of HW limitation. Max size of transfer is only 32B on PPC and
       no more than 20B in current x86 LPC-I2C bridge.*/
    if (num == 1) 
        priv->xfer.cmd = (msgs->flags & I2C_M_RD);
    else 
        priv->xfer.cmd = (msgs[1].flags & I2C_M_RD);

    if (priv->xfer.cmd == I2C_M_RD) {
        if (comm_len == msgs[0].len) {  // Special case of addr_width = 0
            priv->xfer.addr_width = 0;
            priv->xfer.data_len = comm_len;
        }
        else {
            priv->xfer.addr_width = msgs[0].len;
            priv->xfer.data_len = comm_len - priv->xfer.addr_width;
        }
    }
    else {
        /* Addr_width (I2C_NUM_ADDR reg) isn't used in Write command. */
        priv->xfer.addr_width = 0;
        priv->xfer.data_len = comm_len;
    }
}

/* Check if really required */
static int lpci2c_check_cpld_init(struct lpci2c_priv* priv)
{
    int rc = LPCI2C_RC_OK;
    u8 half_cyc_dflt, i2c_hold_dflt;
    u8 reg;

    reg = lpci2c_read(priv, LPCI2C_LPF_REG);
    if (reg != LPCI2C_LPF_DFLT) {
        LPCI2C_LOG_WARNING("Reg 0x%x isn't initialised correctly 0x%x instead 0x%x\n",\
                         LPCI2C_LPF_REG, reg, LPCI2C_LPF_DFLT);
        lpci2c_write(priv, LPCI2C_LPF_REG, LPCI2C_LPF_DFLT);
        LPCI2C_LOG_DBG(3, "CPLD reg 0x%x was corrected to 0x%x\n", LPCI2C_LPF_REG, LPCI2C_LPF_DFLT);
    }

    if (i2c_400khz) {
        half_cyc_dflt = LPCI2C_HALF_CYC_400;
        i2c_hold_dflt = LPCI2C_I2C_HOLD_400;
    }
    else {
        half_cyc_dflt = LPCI2C_HALF_CYC_100;
        i2c_hold_dflt = LPCI2C_I2C_HOLD_100;
    }

    reg = lpci2c_read(priv, LPCI2C_HALF_CYC_REG);
    if (reg != half_cyc_dflt) {
        LPCI2C_LOG_WARNING("Reg 0x%x isn't initialised correctly 0x%x instead 0x%x\n",\
                         LPCI2C_HALF_CYC_REG, reg, half_cyc_dflt);
        //rc += -EFAULT;
        lpci2c_write(priv, LPCI2C_HALF_CYC_REG, half_cyc_dflt);
        LPCI2C_LOG_DBG(3, "CPLD reg 0x%x was corrected to 0x%x\n", LPCI2C_HALF_CYC_REG, half_cyc_dflt);
    }  

    reg = lpci2c_read(priv, LPCI2C_I2C_HOLD_REG);
    if (reg != i2c_hold_dflt) {
        LPCI2C_LOG_WARNING("Reg 0x%x isn't initialised correctly 0x%x instead 0x%x\n",\
                         LPCI2C_I2C_HOLD_REG, reg, i2c_hold_dflt);
        //rc += -EFAULT;
        lpci2c_write(priv, LPCI2C_I2C_HOLD_REG, i2c_hold_dflt);
        LPCI2C_LOG_DBG(3, "CPLD reg 0x%x was corrected to 0x%x\n", LPCI2C_I2C_HOLD_REG, i2c_hold_dflt);
    }
    
	return (!rc ? rc : -EFAULT);
}

/* Reset CPLD LPC-I2C block. ToDo, still note defined in CPLD */
static void lpci2c_reset(struct lpci2c_priv* priv)
{
    u8 val;

    mutex_lock(&priv->lock);
    val = lpci2c_read(priv, LPCI2C_CTRL_REG);
    val &= (~LPCI2C_RST_SEL_MASK);
    lpci2c_write(priv, LPCI2C_CTRL_REG, val);
    mutex_unlock(&priv->lock);

    LPCI2C_LOG_WARNING("Reset LPCI2C bridge\n");
}

/* Make sure the CPLD is ready to start transmitting.
   Return 0 if it is, -EBUSY if it is not. */
static int lpci2c_check_busy(struct lpci2c_priv* priv)
{
    u8 val;

    val = lpci2c_read(priv, LPCI2C_STATUS_REG);

    if ((val & LPCI2C_TRANS_END))
        return LPCI2C_RC_OK;
    else {
        LPCI2C_LOG_DBG(2, "LPCI2C is busy, LPCI2C_STATUS_REG reg: 0x%x\n", val);
        return LPCI2C_RC_FAILURE;
    }
}

static int lpci2c_wait_for_free(struct lpci2c_priv* priv)
{
    int timeout = 0;

    do {
        if (!lpci2c_check_busy(priv)) {
            LPCI2C_LOG_DBG(4, "LPCI2C status free\n");
            break;
        }
        LPCI2C_LOG_DBG(3, "Wait %d for LPCI2C free status\n", timeout);
        msleep(priv->poll_time);
    } while ((timeout += priv->poll_time) < LPCI2C_XFER_TO);

    if (timeout > LPCI2C_XFER_TO) {
        LPCI2C_LOG_ERROR("Wait status free timeout,to %d msec\n", timeout);
        return -ETIMEDOUT;
    }
    else
        return LPCI2C_RC_OK;
}

/*
 * Wait for master transfer to complete.
 * It puts current process to sleep until we get interrupt or timeout expires.
 * Returns the number of transferred /read bytes or error (<0)
 */

static int lpci2c_wait_for_tc(struct lpci2c_priv* priv)
{
    int status, rc = 0;
    int msg_idx = 1, timeout = 0;
    u8 datalen, i;

    if (priv->irq > 0){ /* Interrupt mode */
		rc = wait_event_interruptible_timeout(priv->wq,
			!lpci2c_check_status(priv, &status), priv->adap.timeout);

		if (unlikely(rc < 0)) {
			LPCI2C_LOG_ERROR("wait interrupted\n");
            return rc;
        } else if (!lpci2c_check_status(priv, &status)) {
			LPCI2C_LOG_ERROR("Irq wait timeout\n");
			return -ETIMEDOUT;
		}
	}
    else {  /* Polling mode */
        do {
            msleep(priv->poll_time);
            if (!lpci2c_check_status(priv, &status)) {
                LPCI2C_LOG_DBG(4, "Transaction ended\n");
                break;
            }
            LPCI2C_LOG_DBG(4, "Wait for end transaction\n");
        } while (((status == 0))
             && ((timeout += priv->poll_time) < LPCI2C_XFER_TO));
    }

	switch (status) {
    case LPCI2C_NO_IND:
        LPCI2C_LOG_ERROR("Transfer Timeout, Status isn't updated in %d msec\n", timeout);
        return -ETIMEDOUT;
    case LPCI2C_ACK_IND:
        LPCI2C_LOG_DBG(4, "Status ACK\n");
        if (priv->xfer.cmd == I2C_M_RD) {
            /* Actual read data len will be always the same as requested len. 0xff (line pull-up)
               will be returned if slave has no data to return. Thus don't read LPCI2C_NUM_DAT_REG reg from CPLD. */
            rc = datalen = priv->xfer.data_len;
            if (priv->xfer.msg_num == 1)
                msg_idx = 0;

            if (!(priv->xfer.msg[msg_idx].buf)) {
                LPCI2C_LOG_ERROR("Rx buffer %d NULL\n", msg_idx);
                rc = EINVAL;
            }
            else
                lpci2c_read_comm(priv, LPCI2C_DATA_REG, priv->xfer.msg[msg_idx].buf, datalen);            
#ifdef LPCI2C_DEBUG
            if (dbg_lvl > 1) { 
                priv->stat.read_tr++;
                priv->stat.read_byte += datalen;
                priv->stat.ack++;
                if (dbg_lvl > 3) {
                    LPCI2C_LOG_DBG(5, "Received data in read trans:\n\t");
                    for (i=0; i<datalen; i++) 
                        printk("%02x ", priv->xfer.msg[msg_idx].buf[i]);
                    printk("\n");
                }
            }
#endif
        }
        else {
            rc = priv->xfer.addr_width + priv->xfer.data_len;
            LPCI2C_LOG_DBG(4, "Ack received for write transaction\n");
        }
        break;
    case LPCI2C_NACK_IND:
        LPCI2C_LOG_DBG(2, "NACK indication in transfer to 0x%x\n", priv->xfer.msg[0].addr);
        rc = -EAGAIN;   // -EIO;
#ifdef LPCI2C_DEBUG
        if (dbg_lvl > 1)
            priv->stat.nack++;
#endif
        break;
    case LPCI2C_ERR_IND:
        LPCI2C_LOG_ERROR("Error indication in transfer to 0x%x\n", priv->xfer.msg[0].addr);
        rc = -EIO;
        break;
    default:
        break;
    }

	return rc;
}

irqreturn_t lpci2c_isr(int irq, void *data)
{
    struct lpci2c_priv* priv = (struct lpci2c_priv*)data;

    wake_up_interruptible(&priv->wq);
    
#ifdef LPCI2C_DEBUG
    if (dbg_lvl > 1)
        priv->stat.irq_cnt++;
#endif
    LPCI2C_LOG_DBG(4, "top-half, irq_cnt %u\n", priv->stat.irq_cnt);

	return IRQ_HANDLED;
}

static void lpci2c_xfer_msg(struct lpci2c_priv* priv)
{
    int i, j, len = 0;

    LPCI2C_LOG_DBG(5, "addr 0x%x, data_len %d, addr_width %d\n", priv->xfer.msg[0].addr, priv->xfer.data_len, priv->xfer.addr_width);

    lpci2c_write(priv, LPCI2C_NUM_DAT_REG, priv->xfer.data_len);

    lpci2c_write(priv, LPCI2C_NUM_ADDR_REG, priv->xfer.addr_width);

    for (i = 0; i < priv->xfer.msg_num; i++) {
        if ((priv->xfer.msg[i].flags & I2C_M_RD) != I2C_M_RD) {
            /* Don't write to CPLD buffer in read transaction */
            lpci2c_write_comm(priv, LPCI2C_DATA_REG+len, priv->xfer.msg[i].buf, priv->xfer.msg[i].len);
            len += priv->xfer.msg[i].len;
        }
    }
    /* Set target slave address with command for master transfer.
       It should be latest executed function before CPLD transaction */
    lpci2c_write(priv, LPCI2C_CMD_REG, ((priv->xfer.msg[0].addr << 1) | priv->xfer.cmd));

#ifdef LPCI2C_DEBUG
    if (dbg_lvl > 1) {
        priv->stat.write_byte = len;
        priv->stat.write_tr++;
        LPCI2C_LOG_DBG(5, "LPC %s trans %d, len %d, data_len %d\n", \
                       ((priv->xfer.cmd == I2C_M_RD)? "rx" : "tx"), \
                       priv->stat.write_tr, len, priv->xfer.data_len);
        if (dbg_lvl > 4) {
            for (i = 0; i < priv->xfer.msg_num; i++) {
                if ((priv->xfer.msg[i].flags & I2C_M_RD) != I2C_M_RD) {
                    LPCI2C_LOG_DBG(5, "LPC Trans msg %d:\n\t", i);
                    for (j = 0; j < priv->xfer.msg[i].len; j++)
                        printk("%02x ", *(priv->xfer.msg[i].buf+j));
                    printk("\n");
                }
            }
        }
    }
#endif    
}

/*
 * Generic lpcx - i2c transfer.
 * Returns the number of processed messages or error (<0)
 */
static int lpci2c_xfer(struct i2c_adapter *adap, struct i2c_msg *msgs, int num)
{
    struct lpci2c_priv* priv = (struct lpci2c_priv*)(i2c_get_adapdata(adap));
	int rc;
    u8 comm_len = 0;

	LPCI2C_LOG_DBG(3, "%s, %d msgs\n", __FUNCTION__, num);

	if ((rc = lpci2c_check_msg_params(priv, msgs, num, &comm_len))) {
        LPCI2C_LOG_ERROR("Incorrect message\n");
        return rc;
    }

	/* Check bus state */
	if (lpci2c_wait_for_free(priv)){
		LPCI2C_LOG_ERROR("LPC-I2C bridge is busy\n");

		/* Usually it means something serious has happend.
		 * We *cannot* have unfinished previous transfer
		 * so it doesn't make any sense to try to stop it.
		 * Probably we were not able to recover from the
		 * previous error.
		 * The only *reasonable* thing is soft reset.
		 */
		lpci2c_reset(priv);
        if (lpci2c_check_busy(priv)) {
            LPCI2C_LOG_ERROR("LPC-I2C bridge is busy after reset\n");
            return LPCI2C_RC_FAILURE;
        }
	}

    lpci2c_set_transf_data(priv, msgs, num, comm_len);

    mutex_lock(&priv->lock);
	/* Do real transfer. Can't fail */
	lpci2c_xfer_msg(priv);

    /* Wait for transaction complete */
    rc = lpci2c_wait_for_tc(priv);
    mutex_unlock(&priv->lock);

	return rc < 0 ? rc : num;
}

static u32 lpci2c_func(struct i2c_adapter *adap)
{
	return I2C_FUNC_I2C | I2C_FUNC_SMBUS_EMUL | I2C_FUNC_SMBUS_BLOCK_DATA;
}

static const struct i2c_algorithm lpci2c_algo = {
	.master_xfer 	= lpci2c_xfer,
	.functionality	= lpci2c_func
};

ssize_t show_dbg_lvl(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t rc;

    rc = sprintf(buf, "LPCI2C dbg lvl: %d\n", dbg_lvl);
    return rc+1;
}

ssize_t store_dbg_lvl(struct device *dev, struct device_attribute *attr, const char *buf, size_t cnt)
{
    u32 lvl;
   
    lvl = (u32)simple_strtol(buf, NULL, 10);
    if (lvl > LPCI2C_DBG_MAX_LVL)
        LPCI2C_LOG_ERROR("Incorrect input dbg lvl %d > %d\n", lvl, LPCI2C_DBG_MAX_LVL);
    else {
        dbg_lvl = lvl;
        LPCI2C_LOG_DBG(3, "LPCI2C dbg level has been changed to %d\n", lvl);
    }

    return cnt;
}

ssize_t show_stat(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t rc;
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);

    rc = sprintf(buf, "Mode:\t\t%s\nWrite trans:\t%u\nWrite bytes:\t%lu\nRead trans:\t%u\nRead bytes:\t%lu\nAck recv:\t%u\nNack recv:\t%u\nTimeouts:\t%u\nIrq Cnt:  \t%u\n", \
                 (priv->irq > 0 ? "Interrupt" : "Polling"), priv->stat.write_tr, priv->stat.write_byte, \
                 priv->stat.read_tr, priv->stat.read_byte, priv->stat.ack, priv->stat.nack, \
                 priv->stat.to, priv->stat.irq_cnt);
    return rc+1;
}

ssize_t store_stat(struct device *dev, struct device_attribute *attr, const char *buf, size_t cnt)
{
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);
   
    memset(&priv->stat, 0, sizeof(priv->stat));
    LPCI2C_LOG_DBG(3, "LPCI2C statistic reset\n");

    return cnt;
}

ssize_t show_cpld_params(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t rc;
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);

    rc = sprintf(buf, "LPF reg(0x%x):\t\t0x%x\nHALF_CYC reg(0x%x):\t0x%x\nI2C_HOLD(0x%x)\t0x%x\n",\
                 LPCI2C_LPF_REG, lpci2c_read(priv, LPCI2C_LPF_REG),\
                 LPCI2C_HALF_CYC_REG, lpci2c_read(priv, LPCI2C_HALF_CYC_REG),\
                 LPCI2C_I2C_HOLD_REG, lpci2c_read(priv, LPCI2C_I2C_HOLD_REG));

    return rc+1;
}

ssize_t show_info(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t rc;
    char poll_str[12];
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);

    sprintf(poll_str, " - %d ms\n", priv->poll_time);
    rc = sprintf(buf, "Mode:\t\t%s%sI2C freq:\t%s\nTimeout:\t%u ms\nRetries:\t%u\nStatistic:\t%s\n", \
                 (priv->irq > 0 ? "Interrupt" : "Polling"), \
                 (priv->irq > 0 ? "\n" : poll_str), \
                 i2c_400khz ? "400KHz" : "100KHz", \
                 xfer_to, retr_num, \
                 (dbg_lvl > 1) ? "enabled" : "disabled");
    return rc+1;
}

ssize_t show_io_regions(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t rc;
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);

    rc = sprintf(buf, "IO regions num: %d\nIO region0: %04x-%04x\nIO region1: %04x-%04x\n", \
                 2, (u32)priv->lpc_i2c_res->start, (u32)priv->lpc_i2c_res->end, \
                 (u32)priv->lpc_cpld_res->start, (u32)priv->lpc_cpld_res->end);
    return rc+1;
}

ssize_t show_timeout(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t rc;

    rc = sprintf(buf, "LPCI2C timeout: %d\n", xfer_to);
    return rc+1;
}

ssize_t store_timeout(struct device *dev, struct device_attribute *attr, const char *buf, size_t cnt)
{
    u32 to;
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);

    to = (u32)simple_strtol(buf, NULL, 10);
    LPCI2C_LOG_DBG(3, "LPCI2C timeout has been changed from %d to %d msec\n", xfer_to, to);
    xfer_to = to;
    priv->adap.timeout = to;

    return cnt;
}

ssize_t show_retr_num(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t rc;

    rc = sprintf(buf, "LPCI2C retry num: %d\n", retr_num);
    return rc+1;
}

ssize_t store_retr_num(struct device *dev, struct device_attribute *attr, const char *buf, size_t cnt)
{
    u32 num;
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);

    num = (u32)simple_strtol(buf, NULL, 10);
    LPCI2C_LOG_DBG(3, "LPCI2C retry num has been changed from %d to %d\n", retr_num, num);
    retr_num = num;
    priv->adap.retries = num;

    return cnt;
}

ssize_t show_poll_time(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t rc;
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);

    rc = sprintf(buf, "LPCI2C polling time: %d msec\n", priv->poll_time);
    return rc+1;
}

ssize_t store_poll_time(struct device *dev, struct device_attribute *attr, const char *buf, size_t cnt)
{
    u32 pt;
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);

    pt = (u32)simple_strtol(buf, NULL, 10);
    LPCI2C_LOG_DBG(3, "LPCI2C polling time has been changed from %d to %d\n", priv->poll_time, pt);
    priv->poll_time = pt;

    return cnt;
}

ssize_t show_block_sz(struct device *dev, struct device_attribute *attr, char *buf)
{
    ssize_t rc;

    rc = sprintf(buf, "LPCI2C max data block size: %d\n", block_sz);
    return rc+1;
}

ssize_t store_block_sz(struct device *dev, struct device_attribute *attr, const char *buf, size_t cnt)
{
    u32 sz;

    sz = (u32)simple_strtol(buf, NULL, 10);
    LPCI2C_LOG_DBG(3, "LPCI2C rdata block size has been changed from %d to %d\n", block_sz, sz);
    block_sz = sz;

    return cnt;
}

ssize_t store_reset(struct device *dev, struct device_attribute *attr, const char *buf, size_t cnt)
{
    struct lpci2c_priv* priv = (struct lpci2c_priv*)dev_get_drvdata(dev);

    LPCI2C_LOG_DBG(1, "Reset LPCI2C CPLD block\n");
    lpci2c_reset(priv);

    return cnt;
}

static DEVICE_ATTR(dbg_lvl, 0644, show_dbg_lvl, store_dbg_lvl);
static DEVICE_ATTR(stat, 0644, show_stat, store_stat);
static DEVICE_ATTR(info, 0444, show_info, NULL);
static DEVICE_ATTR(io_regions, 0444, show_io_regions, NULL);
static DEVICE_ATTR(cpld_params, 0444, show_cpld_params, NULL);
static DEVICE_ATTR(timeout, 0644, show_timeout, store_timeout);
static DEVICE_ATTR(retr_num, 0644, show_retr_num, store_retr_num);
static DEVICE_ATTR(poll_time, 0644, show_poll_time, store_poll_time);
static DEVICE_ATTR(block_sz, 0644, show_block_sz, store_block_sz);
static DEVICE_ATTR(reset, 0222, NULL, store_reset);

static struct attribute *lpci2c_attributes[] = {
	&dev_attr_dbg_lvl.attr,
	&dev_attr_stat.attr,
    &dev_attr_info.attr,
    &dev_attr_io_regions.attr,
    &dev_attr_cpld_params.attr,
    &dev_attr_timeout.attr,
    &dev_attr_retr_num.attr,
    &dev_attr_poll_time.attr,
    &dev_attr_block_sz.attr,
    &dev_attr_reset.attr,
	NULL
};

int lpci2c_sysfs_create(struct lpci2c_priv* priv)
{
    priv->attr_grp.attrs = lpci2c_attributes;
	if (sysfs_create_group(&(priv->pdev->dev.kobj), &priv->attr_grp)) {
        LPCI2C_LOG_ERROR("Failed to create sysfs lpci2c group\n");
		return -EACCES;
    }

    return LPCI2C_RC_OK;
}

static int lpc_i2c_dec_rng_config(struct lpci2c_priv* priv, struct pci_dev* pdev, u8 range, u16 base_addr)
{
    u16 rng_reg;
    u32 val;
    int rc;

    if (range >= LPC_PCH_GEN_DEC_RANGES) {
        LPCI2C_LOG_ERROR("Incorrect LPC decode range %d > %d\n", range, LPC_PCH_GEN_DEC_RANGES);
        return -ERANGE;
    }

    rng_reg = LPC_PCH_GEN_DEC_BASE + 4*range;
    rc = pci_read_config_dword(pdev, rng_reg, &val);
    if (rc) {
        LPCI2C_LOG_ERROR("Access to LPC_PCH config failed, rc %d\n", rc);
        return -EFAULT;
    }
    priv->lpc_gen_dec_reg[range] = val;
    LPCI2C_LOG_DBG(4, "LPC Generic Decode Range %d (0x%x) old val: 0x%x\n", range, rng_reg, val);
    /* Clean all bits except reserved */
    val &= (~(0x3F << 18)); 
    val &= ~0xFFFD;

    val |= 0xFFFFFFFF & ((0x3F << 18) | ((base_addr >> 2)<<2) | 1);
    rc = pci_write_config_dword(pdev, rng_reg, val);
    if (rc) {
        LPCI2C_LOG_ERROR("Config of LPC_PCH Generic Decode Range %d failed, rc %d\n", range, rc);
        rc = -EFAULT;
    }
    else {
        LPCI2C_LOG_DBG(1, "LPC Generic Decode Range %d configured: 0x%x\n", range, val);
        rc = LPCI2C_RC_OK;
    }
    return rc;
}

static int lpc_region_request(struct lpci2c_priv* priv)
{
    if (!request_region(lpc_resources[0].start, resource_size(&lpc_resources[0]), LPCI2C_DEVICE_NAME)) {
        LPCI2C_LOG_ERROR("Request ioregion 0x%x len 0x%x for %s failed\n", (u32)lpc_resources[0].start, \
						 (u32)resource_size(&lpc_resources[0]), LPCI2C_DEVICE_NAME);
        return -EIO;
    }
    else
        LPCI2C_LOG_DBG(1, "Access to ioport 0x%x-0x%x is granted\n", (u32)lpc_resources[0].start,\
                       (u32)lpc_resources[0].end);

    if (!request_region(lpc_resources[1].start, resource_size(&lpc_resources[1]), LPCI2C_DEVICE_NAME)) {
        LPCI2C_LOG_ERROR("Request ioregion 0x%x len 0x%x for %s failed\n", (u32)lpc_resources[1].start, \
						 (u32)resource_size(&lpc_resources[1]), LPCI2C_DEVICE_NAME);
        release_region(lpc_resources[0].start, resource_size(&lpc_resources[0]));
        return -EIO;
    }
    else
        LPCI2C_LOG_DBG(1, "Access to ioport 0x%x-0x%x is granted\n", (u32)lpc_resources[1].start,\
                       (u32)lpc_resources[1].end);

    priv->lpc_i2c_res = &lpc_resources[0];
    priv->lpc_cpld_res = &lpc_resources[1];
    return LPCI2C_RC_OK;
}

static int lpc_i2c_lpc_config(struct lpci2c_priv* priv)
{
    struct pci_dev* pdev = NULL;
    u32 val;
    int rc;
    int i;

    pdev = pci_get_bus_and_slot(LPC_PCH_IFC_BUS_ID, PCI_DEVFN(LPC_PCH_IFC_SLOT_ID, LPC_PCH_IFC_FUNC_ID));
    if (!pdev) {
        LPCI2C_LOG_ERROR("LPC controler bus:%d slot:%d func:%d doesn't found\n",\
                       LPC_PCH_IFC_BUS_ID, LPC_PCH_IFC_SLOT_ID, LPC_PCH_IFC_FUNC_ID);
        return -EFAULT;
    }

#ifdef LPCI2C_DEBUG
    if (dbg_lvl >= 3) { 
        for (i=0; i<LPC_PCH_GEN_DEC_RANGES;i++) {
            rc = pci_read_config_dword(pdev, (LPC_PCH_GEN_DEC_BASE + 4*i), &val);
    if (rc) {
                LPCI2C_LOG_ERROR("Access to LPC_PCH config range %d failed, rc %d\n", i, rc);
                continue;
            }
            if ((val & 1)) {
                LPCI2C_LOG_DBG(4, "LPC Generic Decode Range %d is enabled, val 0x%x, base addr 0x%x\n", i, val, ((val&0xffff)>>2));
            }
            else {
                LPCI2C_LOG_DBG(4, "LPC Generic Decode Range %d is disabled\n", i);
            }
        }
    }
#endif

    rc = lpc_i2c_dec_rng_config(priv, pdev, LPC_CPLD_I2C_RANGE, LPC_CPLD_I2C_BASE_ADRR);
    if (rc) {
        LPCI2C_LOG_ERROR("LPC decode range %d config failed, rc %d\n", LPC_CPLD_I2C_RANGE, rc);
        pci_dev_put(pdev);
        return -EFAULT;
    }

    rc = lpc_i2c_dec_rng_config(priv, pdev, LPC_CPLD_RANGE, LPC_CPLD_BASE_ADRR);
    if (rc) {
        LPCI2C_LOG_ERROR("LPC decode range %d config failed, rc %d\n", LPC_CPLD_I2C_RANGE, rc);
        rc = -EFAULT;
    }
   
    pci_dev_put(pdev);
    return rc;
}

static void lpc_i2c_lpc_deconfig(u32 val, u8 range)
{
    struct pci_dev* pdev = NULL;
    int rc;

    pdev = pci_get_bus_and_slot(LPC_PCH_IFC_BUS_ID, PCI_DEVFN(LPC_PCH_IFC_SLOT_ID, LPC_PCH_IFC_FUNC_ID));
    if (!pdev) {
        LPCI2C_LOG_ERROR("LPC controler bus:%d slot:%d func:%d doesn't found\n",\
                       LPC_PCH_IFC_BUS_ID, LPC_PCH_IFC_SLOT_ID, LPC_PCH_IFC_FUNC_ID);
        return;
    }
    
    /* Restore old value */
    rc = pci_write_config_dword(pdev, (LPC_PCH_GEN_DEC_BASE + 4*range), val);
    if (rc)
        LPCI2C_LOG_ERROR("Deconfig of LPC_PCH Generic Decode Range %d failed, rc %d\n", range, rc);
    else 
        LPCI2C_LOG_DBG(1, "LPC Generic Decode Range %d deconfigured: 0x%x\n", range, val);
}

static int __init lpci2c_init(void)
{
	int rc;
	struct lpci2c_priv* priv;
	struct i2c_adapter *adap;
    
    priv = kzalloc(sizeof(struct lpci2c_priv), GFP_KERNEL);
    if (!priv) {
        LPCI2C_LOG_ERROR("Failed to allocate lpci2c_priv\n");
        return -ENOMEM;
    }
    mutex_init(&priv->lock);

    rc = lpc_i2c_lpc_config(priv);
    if (rc) {
        LPCI2C_LOG_ERROR("Failed to configure CPLD LPC range\n");
		goto fail_platform_device1;
    }

    lpci2c_plat_dev = platform_device_alloc(LPCI2C_DEVICE_NAME, -1);
	if (!lpci2c_plat_dev) {
		rc = -ENOMEM;
        LPCI2C_LOG_ERROR("Alloc %s platform device failed\n", LPCI2C_DEVICE_NAME);
		goto fail_platform_device1;
	}

    if (lpc_region_request(priv)) {
        LPCI2C_LOG_ERROR("Request ioregion failed\n");
        goto fail_platform_device1;
    }

	rc = platform_device_add_resources(lpci2c_plat_dev, lpc_resources, ARRAY_SIZE(lpc_resources));
	if (rc) {
		LPCI2C_LOG_ERROR("Device resource i2c addition failed (%d)\n", rc);
		goto fail_platform_device2;
	}

	rc = platform_device_add(lpci2c_plat_dev);
	if (rc) {
        LPCI2C_LOG_ERROR("Add %s platform device failed (%d)\n", LPCI2C_DEVICE_NAME, rc);
		goto fail_platform_device2;
    }

	platform_set_drvdata(lpci2c_plat_dev, priv);
    priv->pdev = lpci2c_plat_dev;

    if (force_irq) {
        init_waitqueue_head(&priv->wq);
        rc = request_irq(LPCI2C_IRQ_NUM, lpci2c_isr, \
                     IRQF_TRIGGER_HIGH, LPCI2C_DEVICE_NAME, priv);
        if (rc) {
            priv->irq = LPCI2C_NO_IRQ;
            LPCI2C_LOG_ERROR("Request irq failed (%d). Poll method will be used\n", rc);
        }
        else {
            priv->irq = LPCI2C_IRQ_NUM;
            LPCI2C_LOG_DBG(1, "Irq %d registered\n", LPCI2C_IRQ_NUM);
        }
    }

	/* Register with i2c layer */
	adap = &priv->adap;
	/* set up the sysfs linkage to our parent device */
	adap->dev.parent = &lpci2c_plat_dev->dev;
	snprintf(adap->name, sizeof(adap->name), "%s bridge controller", LPCI2C_DEVICE_NAME);
	strlcpy(adap->name, LPCI2C_DEVICE_NAME, sizeof(adap->name));
	i2c_set_adapdata(adap, priv);
	adap->class = I2C_CLASS_HWMON | I2C_CLASS_SPD;
	adap->algo = &lpci2c_algo;	
	adap->retries = retr_num;
	adap->nr = LPCI2C_BUS_NUM;
    adap->timeout = msecs_to_jiffies(xfer_to);     /* ToDo, check max possible CPLD TO, fine tuning*/

    priv->poll_time = poll_time;    //xfer_to / retr_num / 10;

	rc = i2c_add_numbered_adapter(adap);
	if (rc) {
		LPCI2C_LOG_ERROR("Add %s adapter failed (%d)\n", LPCI2C_DEVICE_NAME, rc);
		goto fail_platform_device3;
	}
    else
        LPCI2C_LOG_DBG(1, "Add %s adapter to bus %d is done\n", LPCI2C_DEVICE_NAME, LPCI2C_BUS_NUM);
    
	if ((rc = lpci2c_sysfs_create(priv))) {
        LPCI2C_LOG_ERROR("Create sysfs %s group failed\n", LPCI2C_DEVICE_NAME);
		goto fail_platform_device4;
    }
    
    priv->base_addr = LPC_CPLD_I2C_BASE_ADRR;

    lpci2c_check_cpld_init(priv);

    LPCI2C_LOG_DBG(1, "%s initialised\n", LPCI2C_DEVICE_NAME);
	return 0;

fail_platform_device4:
	i2c_del_adapter(adap);
fail_platform_device3:
    if (priv->irq > 0)
        free_irq(priv->irq, priv);
	platform_device_del(lpci2c_plat_dev);
fail_platform_device2:
    platform_device_put(lpci2c_plat_dev);
fail_platform_device1:
    kfree(priv);

    return rc;
}

static void __exit lpci2c_exit(void)
{
	struct lpci2c_priv* priv;

	priv = platform_get_drvdata(lpci2c_plat_dev);
    lpc_i2c_lpc_deconfig(priv->lpc_gen_dec_reg[LPC_CPLD_RANGE], LPC_CPLD_RANGE);
    lpc_i2c_lpc_deconfig(priv->lpc_gen_dec_reg[LPC_CPLD_I2C_RANGE], LPC_CPLD_I2C_RANGE);
	i2c_del_adapter(&priv->adap);
	/* Done by platform_device_del()
	lpc_i2c_res = platform_get_resource(lpci2c_plat_dev, IORESOURCE_IO, 0)
    release_region(lpc_i2c_res->start, resource_size(lpc_i2c_res));*/
    if (priv->irq > 0)
        free_irq(priv->irq, priv);
    sysfs_remove_group(&(lpci2c_plat_dev->dev.kobj), &priv->attr_grp); // Check if required 
	kfree(priv); // Check if required 
	platform_device_unregister(lpci2c_plat_dev);
    LPCI2C_LOG_DBG(1, "%s removed\n", LPCI2C_DEVICE_NAME);   
}

module_init(lpci2c_init);
module_exit(lpci2c_exit);

MODULE_AUTHOR("Mellanox Technologies (Michael Shych)");
MODULE_DESCRIPTION(LPCI2C_MOD_DESCRIPTION);
MODULE_VERSION(LPCI2C_MOD_VERSION);
MODULE_LICENSE("GPL v2");

MODULE_PARM_DESC(force_irq, " force interrupt mode, 1 / 0, default(0) - disabled");
MODULE_PARM_DESC(i2c_400khz, "force 400KHz i2c frequency, 1 / 0, default(0) - 100KHz");
MODULE_PARM_DESC(xfer_to, " transfer timeout in millisec, default - 100");
MODULE_PARM_DESC(poll_time, " polling time in millisec, default - 2");
MODULE_PARM_DESC(retr_num, " access retries num, 1-5, default - 2");
MODULE_PARM_DESC(block_sz, " max data block size, 1-36, default - 36");
MODULE_PARM_DESC(dbg_lvl, " debug level, 0-5, 0 - disabled, default - 1");

