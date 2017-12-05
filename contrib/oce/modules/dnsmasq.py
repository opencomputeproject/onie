
import ipaddr

DEFAULT_LEASE_TIME = 600
DEFAULT_MAX_LEASE_TIME = 7200
DEFAULT_DOMAIN_NAME = 'cloud.local'
DEFAULT_DNS_SERVER = '192.168.1.1'
DEFAULT_DIRS = ['logs', 'tftp-root']
DEFAULT_HOSTS_FILENAME = 'hosts'
DEFAULT_HOSTS_TEMPLATE = \
'''
{{ ip }} {{ hostname }}
'''
DEFAULT_CONF_FILENAME = 'dnsmasq.conf'
DEFAULT_CONF_TEMPLATE = \
'''
{%- if only_dns %}
user={{ user }}
group={{ group }}
interface={{ interface }}
no-dhcp-interface={{ interface }}
no-resolv
no-hosts
addn-hosts={{ hosts_filename }}
expand-hosts
domain={{ dhcp_domain_name }}
no-poll
log-queries
{%- else %}
{%- if enable_dns %}
addn-hosts={{ hosts_filename }}
expand-hosts
no-poll
log-queries
{% endif %}
no-resolv
no-hosts
user={{ user }}
group={{ group }}
interface={{ interface }}
#listen-address=

# Use the following DNS Server
server={{ dhcp_dns_server }}

log-dhcp
dhcp-authoritative
dhcp-lease-max={{ dhcp_max_lease_time }}
leasefile-ro
# onie encap dhcp options
#dhcp-option=encap:CODE, Y, Z

domain={{ dhcp_domain_name }},{{ subnet_cidr }}
{% for subnet in subnets %}
dhcp-range={{ subnet.network }},static
{%- if subnet.gateway %}
dhcp-option:option:router,{{ subnet.gateway }}
{%- else %}
# No default gateway set
dhcp-option=3
{% endif %}
{% endfor %}
{% for host in hosts %}
dhcp-host={{ host.mac_address }},{{ host.ip_address }},{{ host.hostname }}
{% endfor %}

{%- if next_server_addr %}
dhcp-boot=pxelinux,bootserver,{{ dhcp_next_server }}
{%- else %}
{%- if enable_tftp %}
# if enable tftp
enable-tftp
tftp-root={{ tftp_root }}
dhcp-boot=pxelinux.0
{% endif %}
{% endif %}
{% endif %}
'''
DEFAULT_CMD_BINARY = 'dnsmasq'
DEFAULT_CMD_USER = 'nobody'
DEFAULT_CMD_GROUP = 'nogroup'
DEFAULT_CMD_TEMPLATE = \
'''
touch {{ log_file }}
sudo chown {{ user }}:{{ group }} {{ log_file }}
sudo {{ binary }} {{ options }}
'''


def add_subnet(subnets, subnet_cidr_str, gateway_str=None):
    value = {}
    subnet = ipaddr.IPv4Network(subnet_cidr_str)
    value['network'] = subnet.network
    value['netmask'] = subnet.netmask
    value['broadcast'] = subnet.broadcast
    if gateway_str is not None and gateway_str != '':
        gateway = ipaddr.IPv4Address(gateway_str)
        value['gateway'] = gateway

    subnets.append(value)


def add_host(hosts, host):
    value = {}
    value['hostname'] = host['hostname']
    value['mac_address'] = host['mac_address']
    value['ip_address'] = host['ip_address']

    hosts.append(value)


def build_config(output, test_args):
    import os.path
    from jinja2 import Template
    values = {}

    values['dhcp_lease_time'] = DEFAULT_LEASE_TIME
    values['dhcp_max_lease_time'] = DEFAULT_MAX_LEASE_TIME
    values['dhcp_domain_name'] = DEFAULT_DOMAIN_NAME
    values['dhcp_dns_server'] = DEFAULT_DNS_SERVER

    if 'dhcp_lease_time' in test_args:
        values['dhcp_lease_time'] = test_args['dhcp_lease_time']
    if 'dhcp_max_lease_time' in test_args:
        values['dhcp_max_lease_time'] = test_args['dhcp_max_lease_time']
    if 'dhcp_domain_name' in test_args:
        values['dhcp_domain_name'] = test_args['dhcp_domain_name']
    if 'dhcp_dns_server' in test_args:
        values['dhcp_dns_server'] = test_args['dhcp_dns_server']
    if 'tftp_root' in test_args:
        values['tftp_root'] = test_args['tftp_root']

    hosts_filename = os.path.join(test_args['test_dir'],
                                  DEFAULT_HOSTS_FILENAME)
    temp = ipaddr.IPv4Network(test_args['ip_cidr'])
    values['subnet_cidr'] = '{0}/{1}'.format(temp.network, temp.prefixlen)
    gateway_addr = None

    if 'dhcp_gateway' in test_args:
        gateway_addr = test_args['dhcp_gateway']
    if 'dhcp_next_server' in test_args:
        next_server = ipaddr.IPv4Address(test_args['dhcp_next_server'])
        values['dhcp_next_server'] = next_server

    if 'enable_dns' in test_args:
        values['enable_dns'] = test_args['enable_dns']
    if 'only_dns' in test_args:
        values['only_dns'] = test_args['only_dns']
    if 'enable_tftp' in test_args:
        values['enable_tftp'] = test_args['enable_tftp']

    subnets = []
    hosts = []
    add_subnet(subnets, values['subnet_cidr'], gateway_addr)
    add_host(hosts, test_args)

    values['subnets'] = subnets
    values['hosts'] = hosts
    values['interface'] = test_args['interface']
    values['user'] = DEFAULT_CMD_USER
    if 'dhcp_user' in test_args:
        values['user'] = test_args['dhcp_user']

    values['group'] = DEFAULT_CMD_GROUP
    if 'dhcp_group' in test_args:
        values['group'] = test_args['dhcp_group']

    if 'only_dns' in test_args or 'enable_dns' in test_args:
        values['hosts_filename'] = hosts_filename
        host_temp = Template(DEFAULT_HOSTS_TEMPLATE)
        host_file = open(hosts_filename, 'w')
        ip_addr = test_args['dns_server_ip']
        hostname = test_args['dns_server_name']
        host_file.write(host_temp.render(ip=ip_addr, hostname=hostname))
        host_file.close()

    template = Template(DEFAULT_CONF_TEMPLATE)
    output.write(template.render(values))


def build_cmd(output, test_args):
    import os.path
    from jinja2 import Template

    values = {}
    log_file = os.path.join(test_args['test_dir'], 'logs', 'dnsmasq.log')
    values['log_file'] = log_file
    values['binary'] = DEFAULT_CMD_BINARY
    if 'dhcp_binary' in test_args:
        values['binary'] = test_args['dhcp_binary']

    values['user'] = DEFAULT_CMD_USER
    if 'dhcp_user' in test_args:
        values['user'] = test_args['dhcp_user']

    values['group'] = DEFAULT_CMD_GROUP
    if 'dhcp_group' in test_args:
        values['group'] = test_args['dhcp_group']

    args = []
    conf_filename = os.path.join(test_args['test_dir'], DEFAULT_CONF_FILENAME)
    args.append('--keep-in-foreground')
    args.append('--log-facility={0}'.format(log_file))
    args.append('--conf-file={0}'.format(conf_filename))
    values['options'] = ' '.join(args)

    template = Template(DEFAULT_CMD_TEMPLATE)
    output.write(template.render(values))
