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

#ifndef __LPC_I2C_H__
#define __LPC_I2C_H__

#include <linux/i2c.h>

#define LPCI2C_RC_FAILURE     -1
#define LPCI2C_RC_OK          0

#define LPCI2C_DEVICE_NAME    "lpci2c"
#define LPCI2C_IRQ_NUM        19    // TBD
#define LPCI2C_NO_IRQ         -1

#define LPCI2C_VALID_FLAG   I2C_M_RECV_LEN | I2C_M_RD

#define LPCI2C_BUS_NUM      1
#define LPC_CPLD_I2C_BASE_ADRR  0x2000
#define LPC_CPLD_BASE_ADRR      0x2500

#define LPC_CPLD_IO_LEN     0x100
#define LPCI2C_DATA_REG_SZ  36
#define LPCI2C_MAX_ADDR_LEN 4
#define LPCI2C_RETR_NUM     2
#define LPCI2C_XFER_TO      100 // millicec
#define LPCI2C_POLL_TIME    2   // millisec

/* LPC IFC in PCH defines */
#define LPC_PCH_IFC_BUS_ID      0
#define LPC_PCH_IFC_SLOT_ID     31
#define LPC_PCH_IFC_FUNC_ID     0
/* Use generic decode range 4 for CPLD LPC */
#define LPC_PCH_GEN_DEC_RANGE4  0x90
#define LPC_PCH_GEN_DEC_BASE    0x84
/* NOTE! Intel PCH datasheet call ranges from 1 */
#define LPC_PCH_GEN_DEC_RANGES  4
#define LPC_CPLD_I2C_RANGE      2
#define LPC_CPLD_RANGE          3

struct lpc_rw_msg {
	__u16 base;
	__u16 offset;
	__u8 read_write;
	__u8 datalen;
	char* data;
};

struct lpci2c_regs {
	u8 lpf;
	u8 half_cyc;
	u8 i2c_hold;
	u8 config;
	u8 cmd;
	u8 num_dat;
	u8 num_addr;
    u8 status;
	u8 data[LPCI2C_DATA_REG_SZ];
};

struct lpci2c_stat {
    u32 read_tr;
    u32 write_tr;
    u32 irq_cnt;
    unsigned long read_byte;
    unsigned long write_byte;
    u32 ack;
    u32 nack;
    u32 to;
    u32 last_xfer_time;
};

struct lpci2c_curr_transf {
    u8 cmd;
    u8 addr_width;
    u8 data_len;
    u8 msg_num;
    struct i2c_msg* msg;
};

struct lpci2c_priv {
    u32 lpc_gen_dec_reg[LPC_PCH_GEN_DEC_RANGES];
	struct i2c_adapter adap;
	u16 base_addr;
    u16 poll_time;
    struct mutex lock;
    struct resource* lpc_i2c_res;
    struct resource* lpc_cpld_res;
    struct lpci2c_curr_transf xfer;
    wait_queue_head_t wq;
    int irq;
    struct lpci2c_stat stat;
    struct platform_device* pdev;
    struct attribute_group attr_grp; // Check if needed
};

/* LPC I2C registers */
#define LPCI2C_LPF_REG      0x0
#define LPCI2C_CTRL_REG     0x1
#define LPCI2C_HALF_CYC_REG 0x4
#define LPCI2C_I2C_HOLD_REG 0x5
#define LPCI2C_CMD_REG      0x6
#define LPCI2C_NUM_DAT_REG  0x7
#define LPCI2C_NUM_ADDR_REG 0x8
#define LPCI2C_STATUS_REG   0x9
#define LPCI2C_DATA_REG     0xa


#define LPCI2C_RST_SEL_MASK     0x1

#define LPCI2C_LPF_DFLT         0x2
// 100 KHz configuration     
#define LPCI2C_HALF_CYC_100     0x29
#define LPCI2C_I2C_HOLD_100     0x29
// 400 KHz configuration
#define LPCI2C_HALF_CYC_400     0xa
#define LPCI2C_I2C_HOLD_400     0xa

#define LPCI2C_TRANS_END        0x1
#define LPCI2C_STATUS_NACK      0x10

#define LPCI2C_ERR_IND  -1
#define LPCI2C_NO_IND   0
#define LPCI2C_ACK_IND  1
#define LPCI2C_NACK_IND 2

/* 5 debug levels: 1 - only init/exit mesaages, 2 - 1 + statistic enabled, 3-5 - additional increased verbosity levels. */
#define LPCI2C_DBG_MAX_LVL        5
#define LPCI2C_DFLT_DBG_LVL       1
#define LPCI2C_LOG_ERROR(format, args...) printk(KERN_ERR "LPCI2C ERR: " format, ## args)
#define LPCI2C_LOG_WARNING(format, args...) printk(KERN_WARNING "LPCI2C WARN: " format, ## args)
#ifdef  LPCI2C_DEBUG
#define LPCI2C_LOG_DBG(level, format, args...)  if (dbg_lvl > 0 &&  dbg_lvl >= level) {printk("LPCI2C DBG: " format, ## args);}
#else
#define LPCI2C_LOG_DBG(level, format, args...)
#endif

void mlnx_rw_lpc(struct lpc_rw_msg *msg);
#endif /* __LPC_I2C_H__ */
