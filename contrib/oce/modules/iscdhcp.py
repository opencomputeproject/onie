
import ipaddr

DEFAULT_LEASE_TIME = 600
DEFAULT_MAX_LEASE_TIME = 7200
DEFAULT_DOMAIN_NAME = 'cloud.local'
DEFAULT_DNS_SERVER = '192.168.1.1'
DEFAULT_DIRS = ['logs']
DEFAULT_CONF_FILENAME = 'dhcpd.conf'

DEFAULT_CONF_TEMPLATE = \
'''
ddns-update-style none;
Allow booting;
Allow bootp;

{%- if dhcp_server_identifier %}
server-identifier {{ dhcp_server_identifier }};
{% endif %}

# Create an option namespace called ONIE for VIVSO (option 125)
option space onie code width 1 length width 1;

# Define the code names and data types within the ONIE namespace
option onie.installer_url code 1 = text;
option onie.updater_url   code 2 = text;
option onie.machine       code 3 = text;
option onie.arch          code 4 = text;
option onie.machine_rev   code 5 = text;

# Package the ONIE namespace into option 125
option space vivso code width 4 length width 1;
option vivso.onie code 42623 = encapsulate onie;
option vivso.iana code 0 = string;
option op125 code 125 = encapsulate vivso;

#
log-facility local7;
# Logging constructs to assist with debugging
log(error, concat("vendor-class: ",
    substring(option vendor-class-identifier, 0, 11)));
log(error, concat("platform    : ",
    substring(option vendor-class-identifier, 12, 999)));

option domain-name "{{ dhcp_domain_name }}";
option domain-name-servers {{ dhcp_dns_server }};

default-lease-time {{ dhcp_lease_time }};
max-lease-time {{ dhcp_max_lease_time }};

{%- if vivso_url %}
class "onie-vendor-classes" {
    match if substring(option vendor-class-identifier, 0, 11) = "onie_vendor";
    option vivso.iana 01:01:01;
    option onie.{{ onie_action }}_url = "{{ vivso_url }}";
}
{% endif %}

{%- for subnet in subnets %}
subnet {{ subnet.network }} netmask {{ subnet.netmask }} {
    authoritative;
    {%- if subnet.gateway %}
    option routers {{ subnet.gateway }};
    {% endif %}
    option broadcast-address {{ subnet.broadcast }};
    {%- if subnet.next_server %}
    option routers {{ subnet.next_server }};
    {% endif %}
    {%- if default_url %}
    option default-url "{{ default_url }}";
    {% endif %}
    deny unknown-clients;
}

{% endfor %}
{%- for host in hosts %}
host {{ host.hostname }}
{
    option host-name "{{ host.hostname }}";
    hardware ethernet {{ host.mac_address }};
    fixed-address {{ host.ip_address }};
    {%- if tftp_filename %}
    filename "{{ tftp_filename }}";
    {% endif %}
    {%- if tftp_server_ip %}
    next-server {{ tftp_server_ip }};
    {% endif %}
    {%- if tftp_server_name %}
    option tftp-server-name "{{ tftp_server_name }}";
    {% endif %}
    {%- if www_server_ip %}
    option www-server {{ www_server_ip }};
    {% endif %}
}

{% endfor %}
'''
DEFAULT_CMD_BINARY = 'dhcpd'
DEFAULT_CMD_USER = 'nobody'
DEFAULT_CMD_GROUP = 'nogroup'
DEFAULT_CMD_TEMPLATE = \
'''
touch {{ log_file }}
touch {{ lease_file }}
sudo chown {{ user }}:{{ group }} {{ log_file }}
sudo chown {{ user }}:{{ group }} {{ lease_file }}
sudo {{ binary }} {{ options }}
'''


def add_subnet(subnets, subnet_cidr_str, gateway_str=None,
               next_server_str=None):
    value = {}
    subnet = ipaddr.IPv4Network(subnet_cidr_str)
    value['network'] = subnet.network
    value['netmask'] = subnet.netmask
    value['broadcast'] = subnet.broadcast
    if gateway_str is not None and gateway_str != '':
        gateway = ipaddr.IPv4Address(gateway_str)
        value['gateway'] = gateway
    if next_server_str is not None and next_server_str != '':
        next_server = ipaddr.IPv4Address(next_server_str)
        value['next_server'] = next_server

    subnets.append(value)


def add_host(hosts, host):
    value = {}
    value['hostname'] = host['hostname']
    value['mac_address'] = host['mac_address']
    value['ip_address'] = host['ip_address']

    hosts.append(value)


def build_config(output, test_args):
    from jinja2 import Template
    values = {}
    subnets = []
    hosts = []

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

    if 'default_url' in test_args:
        values['default_url'] = test_args['default_url']

    if 'vivso_url' in test_args:
        values['vivso_url'] = test_args['vivso_url']

    if 'onie_action' in test_args:
        values['onie_action'] = test_args['onie_action']

    if 'tftp_filename' in test_args:
        values['tftp_filename'] = test_args['tftp_filename']

    if 'tftp_server_ip' in test_args:
        values['tftp_server_ip'] = test_args['tftp_server_ip']

    if 'tftp_server_name' in test_args:
        values['tftp_server_name'] = test_args['tftp_server_name']

    if 'www_server_ip' in test_args:
        values['www_server_ip'] = test_args['www_server_ip']

    if 'dhcp_server_identifier' in test_args:
        values['dhcp_server_identifier'] = test_args['dhcp_server_identifier']

    subnet_cidr = test_args['ip_cidr']
    gateway_addr = None
    next_server_addr = None

    if 'dhcp_gateway' in test_args:
        gateway_addr = test_args['dhcp_gateway']

    if 'dhcp_next_server' in test_args:
        next_server_addr = test_args['dhcp_next_server']

    add_subnet(subnets, subnet_cidr, gateway_addr, next_server_addr)
    add_host(hosts, test_args)

    values['subnets'] = subnets
    values['hosts'] = hosts
    template = Template(DEFAULT_CONF_TEMPLATE)
    output.write(template.render(values))


def build_cmd(output, test_args):
    import os.path
    from jinja2 import Template

    values = {}
    log_file = os.path.join(test_args['test_dir'], 'logs', 'iscdhcpd.log')
    lease_file = os.path.join(test_args['test_dir'], 'logs', 'dhcpd.leases')
    values['log_file'] = log_file
    values['lease_file'] = lease_file
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
    args.append('-f')
    args.append('--no-pid')
    args.append('-cf {0}'.format(conf_filename))
    args.append('-lf {0}'.format(lease_file))
    args.append(test_args['interface'])
    values['options'] = ' '.join(args)

    template = Template(DEFAULT_CMD_TEMPLATE)
    output.write(template.render(values))
