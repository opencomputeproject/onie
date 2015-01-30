
DEFAULT_CONF_FILENAME = None
DEFAULT_DIRS = ['logs', 'tftp-root']
DEFAULT_CMD_BINARY = 'in.tftpd'
DEFAULT_CMD_USER = 'nobody'
DEFAULT_CMD_GROUP = 'nogroup'
DEFAULT_CMD_TEMPLATE = \
'''
touch {{ log_file }}
sudo chown {{ user }}:{{ group }} {{ log_file }}
chmod -R 777 {{ tftp_root }}
sudo chown -R {{ user }}:{{ group }} {{ tftp_root }}
sudo {{ binary }} {{ options }} {{ tftp_root }}
'''


def build_cmd(output, test_args):
    import os.path
    from jinja2 import Template

    values = {}
    log_file = os.path.join(test_args['test_dir'], 'logs', 'tftpdhpa.log')
    values['log_file'] = log_file
    tftp_root = os.path.join(test_args['test_dir'], 'tftp-root')
    values['tftp_root'] = tftp_root

    values['binary'] = DEFAULT_CMD_BINARY
    if 'tftp_binary' in test_args:
        values['binary'] = test_args['tftp_binary']

    values['user'] = DEFAULT_CMD_USER
    if 'tftp_user' in test_args:
        values['user'] = test_args['tftp_user']

    values['group'] = DEFAULT_CMD_GROUP
    if 'tftp_group' in test_args:
        values['group'] = test_args['tftp_group']

    args = []
    args.append('--foreground')
    args.append('-vvv')
    args.append('-p')
    args.append('-s')
    if 'host_ipv4_addr' in test_args:
        args.append('--address {0}'.format(test_args['host_ipv4_addr']))
    else:
        args.append('--address HOST_IP')
    args.append('--user {0[user]}'.format(values))

    values['options'] = ' '.join(args)

    template = Template(DEFAULT_CMD_TEMPLATE)
    output.write(template.render(values))
