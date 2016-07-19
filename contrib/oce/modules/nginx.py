
DEFAULT_DIRS = ['logs', 'www-root']
DEFAULT_CONF_FILENAME = 'nginx.conf'
DEFAULT_CONF_TEMPLATE = \
'''
user {{ user }} {{ group }};
daemon off;
worker_processes 4;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    log_format onie '$http_ONIE_SERIAL_NUMBER $http_ONIE_ETH_ADDR'
                    '$http_ONIE_VENDOR_ID'
                    '$http_ONIE_MACHINE $http_ONIE_MACHINE_REV'
                    '$http_ONIE_ARCH'
                    '$http_ONIE_OPERATION';

    default_type application/octet-stream;
    access_log {{ access_log }} onie;
    error_log {{ error_log }};

    gzip on;
    gzip_disable "msie6";
    server {
        listen {{ listen_port }} default_server;
        listen [::]:{{ listen_port }} default_server ipv6only=on;

        root {{ web_root }};
        index index.html index.htm;

        server_name localhost;

        location / {
            try_files $uri $uri/ =404;
        }
    }
}
'''
DEFAULT_CMD_BINARY = 'nginx'
DEFAULT_CMD_USER = 'nobody'
DEFAULT_CMD_GROUP = 'nogroup'
DEFAULT_CMD_TEMPLATE = \
'''
touch {{ access_log }}
touch {{ error_log }}
sudo chown {{ user }}:{{ group }} {{ access_log }}
sudo chown {{ user }}:{{ group }} {{ error_log }}
sudo {{ binary }} {{ options }}
'''


def build_config(output, test_args):
    import os.path
    from jinja2 import Template

    values = {}
    values['access_log'] = os.path.join(test_args['test_dir'], 'logs',
                                        'nginx-access.log')
    values['error_log'] = os.path.join(test_args['test_dir'], 'logs',
                                       'nginx-error.log')
    values['web_root'] = os.path.join(test_args['test_dir'], 'www-root')
    values['listen_port'] = 80
    if 'http_port' in test_args:
        values['listen_port'] = test_args['http_port']

    values['user'] = DEFAULT_CMD_USER
    if 'http_user' in test_args:
        values['user'] = test_args['http_user']

    values['group'] = DEFAULT_CMD_GROUP
    if 'http_group' in test_args:
        values['group'] = test_args['http_group']

    template = Template(DEFAULT_CONF_TEMPLATE)
    output.write(template.render(values))


def build_cmd(output, test_args):
    import os.path
    from jinja2 import Template

    values = {}
    values['access_log'] = os.path.join(test_args['test_dir'], 'logs',
                                        'nginx-access.log')
    values['error_log'] = os.path.join(test_args['test_dir'], 'logs',
                                       'nginx-error.log')
    values['binary'] = DEFAULT_CMD_BINARY
    if 'http_binary' in test_args:
        values['binary'] = test_args['http_binary']

    values['user'] = DEFAULT_CMD_USER
    if 'http_user' in test_args:
        values['user'] = test_args['http_user']

    values['group'] = DEFAULT_CMD_GROUP
    if 'http_group' in test_args:
        values['group'] = test_args['http_group']

    args = []
    conf_filename = os.path.join(test_args['test_dir'], DEFAULT_CONF_FILENAME)
    args.append('-c {0}'.format(conf_filename))
    values['options'] = ' '.join(args)

    template = Template(DEFAULT_CMD_TEMPLATE)
    output.write(template.render(values))
