#!/usr/bin/env python

# -----------------------------------------------------------------------------
# Copyright (C) 2014-2016 Carlos Cardenas <carlos@cumulusnetworks.com>
#
# SPDX-License-Identifier:     GPL-2.0
#
# -----------------------------------------------------------------------------

import logging
import os
import os.path
import re
import sys

from oce import OPTIONS, PRETTY_OPTIONS, MAC_REGEX

LOADED_MODULES = {}
TEST_DEFINE = {}
DUT_CONFIG = {}
DEFAULT_OUTPUT_DIR = 'output'

# logger
logger = logging.getLogger('OCE')


def load_modules():
    global LOADED_MODULES
    import modules as MODS

    modules = TEST_DEFINE['available-services']
    for m in modules.keys():
        module_name = 'modules.{0}'.format(modules[m])
        if m == 'dhcp':
            if modules[m] in MODS.SUPPORTED_DHCP:
                LOADED_MODULES['dhcp'] = __import__(module_name,
                                                    fromlist=[modules[m]])
            else:
                logger.critical('Unsupported backend for dhcp: {0}'.format(
                                modules[m]))
                sys.exit(-2)
        elif m == 'dns':
            if modules[m] in MODS.SUPPORTED_DNS:
                LOADED_MODULES['dns'] = __import__(module_name,
                                                   fromlist=[modules[m]])
            else:
                logger.critical('Unsupported backend for dns: {0}'.format(
                                modules[m]))
                sys.exit(-2)
        elif m == 'tftp':
            if modules[m] in MODS.SUPPORTED_TFTP:
                LOADED_MODULES['tftp'] = __import__(module_name,
                                                    fromlist=[modules[m]])
            else:
                logger.critical('Unsupported backend for tftp: {0}'.format(
                                modules[m]))
                sys.exit(-2)
        elif m == 'http':
            if modules[m] in MODS.SUPPORTED_HTTP:
                LOADED_MODULES['http'] = __import__(module_name,
                                                    fromlist=[modules[m]])
            else:
                logger.critical('Unsupported backend for http: {0}'.format(
                                modules[m]))
                sys.exit(-2)
        elif m == 'hands':
            if modules[m] in MODS.SUPPORTED_HANDS:
                LOADED_MODULES['hands'] = __import__(module_name,
                                                     fromlist=[modules[m]])
            else:
                logger.critical('Unsupported backend for hands: {0}'.format(
                                modules[m]))
                sys.exit(-2)
        elif m == 'pdu':
            if modules[m] in MODS.SUPPORTED_PDU:
                LOADED_MODULES['pdu'] = __import__(module_name,
                                                   fromlist=[modules[m]])
            else:
                logger.critical('Unsupported backend for pdu: {0}'.format(
                                modules[m]))
                sys.exit(-2)


def validate_test_num(test_num):
    return str(test_num) in TEST_DEFINE['tests']


def fix_mac_address(mac_str):
    if validate_mac_address(mac_str) is True:
        return mac_str

    if len(mac_str) == 12:
        # all numbers, no ':' separators
        # need to add ':' after every two chars
        mac = '{0}:{1}:{2}:{3}:{4}:{5}'.format(mac_str[0:2], mac_str[2:4],
                                               mac_str[4:6], mac_str[6:8],
                                               mac_str[8:10], mac_str[10:12])
        return mac

    return None


def validate_mac_address(mac_address_str):
    return MAC_REGEX.match(mac_address_str) is not None and \
        len(mac_address_str) == 17


def validate_ip_cidr(ip_cidr_str):
    try:
        import ipaddr
        return ipaddr.IPv4Network(ip_cidr_str) is not None
    except ImportError:
        logger.critical('ipaddr module is not in path')
        return False
    except ipaddr.AddressValueError:
        return False


def validate_options(options):
    # check all keys in args.option to ensure they are supported
    # while checking, type convert
    for key, value in options.iteritems():
        if key in OPTIONS.keys():
            options[key] = OPTIONS[key](value)
        else:
            logger.critical('Unsupported option: {0}'.format(key))
            parser.print_help()
            sys.exit(-1)


def load_dut_config(filename):
    import json
    global DUT_CONFIG
    try:
        DUT_CONFIG = json.load(open(filename, 'r'))
        logger.info('Loaded DUT config from {0}'.format(filename))

        # check mac_address and ip_cidr
        if validate_mac_address(DUT_CONFIG['mac_address']) is False:
            fixed_mac = fix_mac_address(DUT_CONFIG['mac_address'])
            if fixed_mac is None:
                logger.critical('Invalid MAC Address in DUT Config')
                sys.exit(-1)
            DUT_CONFIG['mac_address'] = fixed_mac

        if validate_ip_cidr(DUT_CONFIG['ip_cidr']) is False:
            logger.critical('Invalid DUT CIDR in DUT Config')
            sys.exit(-1)

        # check options
        if DUT_CONFIG['options'] is not None and\
           len(DUT_CONFIG['options'].keys()) > 0:
            validate_options(DUT_CONFIG['options'])
    except:
        logger.critical('Invalid DUT config file. Aborting...')
        sys.exit(-1)
    # name, mac_address, ip_cidr
    # options => option_name/value


def load_tests(filename):
    import json
    global TEST_DEFINE
    try:
        TEST_DEFINE = json.load(open(filename, 'r'))
        logger.info('Loaded {0} tests from {1}'.
                    format(len(TEST_DEFINE['tests'].keys()), filename))
        # check if dnsmasq is used as a service
        modules = TEST_DEFINE['available-services']
        if modules['dhcp'] == 'dnsmasq' or \
           modules['tftp'] == 'dnsmasq':
            # if so, make sure it's both the dhcp and tftp service
            if modules['dhcp'] != modules['tftp']:
                logger.critical('If using dnsmasq, both dhcp and tftp ' +
                                'services must be dnsmasq. Aborting...')
                sys.exit(-1)
        # if not, fail
    except:
        logger.critical('Invalid Test Definition File. Aborting...')
        sys.exit(-1)
    # name, available-services => service/module, names => name/regex
    # tests => num/{name,required-services,action}


def list_tests():
    tests = TEST_DEFINE['tests']
    sorted_keys = sorted(tests.keys(), key=lambda k: int(k))
    for k in sorted_keys:
        print 'Test {0} => {1}'.format(k, tests[k]['name'])


def test_case_file_name(test_args):
    '''
    This function is highly coupled to the ONIE spec and test document
    DO NOT EDIT this function without referencing the spec.
    This function ensures all necessary onie_* options are present
    '''
    # we need to get the name template and return the new name
    # return None if not required
    s_name = map(lambda x: x.strip(), test_args['test']['name'].split('-'))
    if s_name[-1] in TEST_DEFINE['names']:
        from jinja2 import Template
        template = Template(TEST_DEFINE['names'][s_name[-1]])
        # build keyword dict
        keywords = {}
        keywords['action'] = test_args['test']['action']
        if s_name[-1] == 'Name 1':
            if 'onie_arch' not in test_args:
                logger.critical('missing option onie_arch')
                sys.exit(-3)
            else:
                keywords['arch'] = test_args['onie_arch']
            if 'onie_vendor' not in test_args:
                logger.critical('missing option onie_vendor')
                sys.exit(-3)
            else:
                keywords['vendor'] = test_args['onie_vendor']
            if 'onie_machine' not in test_args:
                logger.critical('missing option onie_machine')
                sys.exit(-3)
            else:
                keywords['machine'] = test_args['onie_machine']
            if 'onie_machine_rev' not in test_args:
                logger.critical('missing option onie_machine_rev')
                sys.exit(-3)
            else:
                keywords['machine_rev'] = test_args['onie_machine_rev']
        elif s_name[-1] == 'Name 2':
            if 'onie_arch' not in test_args:
                logger.critical('missing option onie_arch')
                sys.exit(-3)
            else:
                keywords['arch'] = test_args['onie_arch']
            if 'onie_vendor' not in test_args:
                logger.critical('missing option onie_vendor')
                sys.exit(-3)
            else:
                keywords['vendor'] = test_args['onie_vendor']
            if 'onie_machine' not in test_args:
                logger.critical('missing option onie_machine')
                sys.exit(-3)
            else:
                keywords['machine'] = test_args['onie_machine']
        elif s_name[-1] == 'Name 3':
            if 'onie_vendor' not in test_args:
                logger.critical('missing option onie_vendor')
                sys.exit(-3)
            else:
                keywords['vendor'] = test_args['onie_vendor']
            if 'onie_machine' not in test_args:
                logger.critical('missing option onie_machine')
                sys.exit(-3)
            else:
                keywords['machine'] = test_args['onie_machine']
        elif s_name[-1] == 'Name 4':
            if 'onie_arch' not in test_args:
                logger.critical('missing option onie_arch')
                sys.exit(-3)
            else:
                keywords['arch'] = test_args['onie_arch']
            if 'onie_switch_asic' not in test_args:
                logger.critical('missing option onie_switch_asic')
                sys.exit(-3)
            else:
                keywords['switch_asic'] = test_args['onie_switch_asic']
        elif s_name[-1] == 'Name 5':
            if 'onie_arch' not in test_args:
                logger.critical('missing option onie_arch')
                sys.exit(-3)
            else:
                keywords['arch'] = test_args['onie_arch']
        return template.render(keywords)
    return None


def validate_network_info(test_args):
    import ipaddr
    import netifaces
    import socket

    # check interface is present
    if test_args['interface'] not in netifaces.interfaces():
        logger.critical('Interface {0} is not present on the system'.format(
                        test_args['interface']))
        sys.exit(-3)

    # check if DUT information is contained in network on interface
    net_addrs = netifaces.ifaddresses(test_args['interface'])
    # AF_INET has addr, broadcast, and netmask
    # AF_INET6 has addr and netmask
    # AF_PACKET has addr and broadcast

    if netifaces.AF_INET not in net_addrs:
        logger.critical('Interface {0} does not have a IPv4 address'.format(
                        test_args['interface']))
        sys.exit(-3)

    if netifaces.AF_INET6 not in net_addrs:
        logger.critical('Interface {0} does not have a IPv6 address'.format(
                        test_args['interface']))
        sys.exit(-3)

    # Get first INET address
    inet = net_addrs[netifaces.AF_INET][0]
    ipv4_network = ipaddr.IPv4Network('{0[addr]}/{0[netmask]}'.format(inet))
    dut_address = ipaddr.IPv4Address(test_args['ip_address'])
    dut_cidr = ipaddr.IPv4Network(test_args['ip_cidr'])

    test_args['host_ipv4_addr'] = inet['addr']
    test_args['host_local_name'] = socket.gethostname()

    # Check dut_address
    if ipv4_network.Contains(dut_address) is False:
        logger.critical('Interface {0} cannot support DUT address {1}'.
                        format(test_args['interface'], dut_address))
        sys.exit(-3)
    # Check dut_cidr
    temp_cidr = ipaddr.IPv4Network('{0}/{1}'.format(
                                   dut_address, dut_cidr.prefixlen))
    if ipv4_network.Contains(temp_cidr) is False:
        logger.critical('Interface {0} cannot support DUT cidr {1}'.
                        format(test_args['interface'], test_args['ip_cidr']))
        sys.exit(-3)

    if dut_cidr.prefixlen == 32:
        logger.critical('DUT CIDR prefixlen {0} is invalid'.
                        format(dut_cidr.prefixlen))
        sys.exit(-3)


def prepare_test_case(test_args):
    '''
    This function is highly coupled to the ONIE spec and test document
    DO NOT EDIT *_cases without referencing the spec.
    This function ensures all dhcp and dns options are present
    '''

    vivso_cases = [9, 69]
    default_url_cases = [10, 70]
    tftp_filename_cases = [11, 12, 13, 71, 72, 73]
    tftp_server_ip_cases = [11, 20, 21, 22, 23, 24, 25, 56, 57, 58, 59, 60, 61,
                            71, 80, 81, 82, 83, 84, 85, 116, 117, 118, 119,
                            120, 121]
    tftp_server_name_cases = [12, 72]
    www_server_cases = [14, 15, 16, 17, 18, 19, 74, 75, 76, 77, 78, 79]
    dhcp_server_cases = [26, 27, 28, 29, 30, 31, 86, 87, 88, 89, 90, 91]
    dns_server_cases = [32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43,
                        92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103]

    # handle onie_action
    action = test_args['test']['action']
    if action in ['installer', 'updater']:
        test_args['onie_action'] = action

    # for vivso, default_url, and tftp_filename, check for a new filename
    new_filename = test_case_file_name(test_args)
    if new_filename is not None:
        base_filename = os.path.basename(new_filename)
    else:
        base_filename = os.path.basename(test_args['test_filename'])

    test_num = int(test_args['test_num'])

    # handle vivso_url
    if test_num in vivso_cases:
        ip_addr = 'WWW_SERVER_IP'
        if 'host_ipv4_addr' in test_args:
            ip_addr = test_args['host_ipv4_addr']
        test_args['vivso_url'] = 'http://{0}/{1}'.format(ip_addr,
                                                         base_filename)

    # handle default_url
    if test_num in default_url_cases:
        ip_addr = 'WWW_SERVER_IP'
        if 'host_ipv4_addr' in test_args:
            ip_addr = test_args['host_ipv4_addr']
        test_args['default_url'] = 'http://{0}/{1}'.format(ip_addr,
                                                           base_filename)

    # handle tftp_filename
    if test_num in tftp_filename_cases:
        test_args['tftp_filename'] = base_filename

    # handle tftp_server_ip
    if test_num in tftp_server_ip_cases:
        ip_addr = 'TFTP_SERVER_IP'
        if 'host_ipv4_addr' in test_args:
            ip_addr = test_args['host_ipv4_addr']
        test_args['tftp_server_ip'] = ip_addr

    # handle tftp_server_name
    if test_num in tftp_server_name_cases:
        hostname = 'TFTP_SERVER_NAME'
        dns_server_ip = 'DNS_SERVER_IP'
        if 'host_local_name' in test_args:
            hostname = test_args['host_local_name']
        if 'host_ipv4_addr' in test_args:
            dns_server_ip = test_args['host_ipv4_addr']
        test_args['tftp_server_name'] = hostname
        test_args['dns_server_name'] = hostname
        test_args['dns_server_ip'] = dns_server_ip

    # handle dns_server_name
    if test_num in dns_server_cases:
        dns_server_ip = 'DNS_SERVER_IP'
        if 'host_ipv4_addr' in test_args:
            dns_server_ip = test_args['host_ipv4_addr']
        test_args['dns_server_ip'] = dns_server_ip
        test_args['dns_server_name'] = 'onie-server'
        test_args['dhcp_dns_server'] = dns_server_ip

    # handle www_server_ip
    if test_num in www_server_cases:
        ip_addr = 'WWW_SERVER_IP'
        if 'host_ipv4_addr' in test_args:
            ip_addr = test_args['host_ipv4_addr']
        test_args['www_server_ip'] = ip_addr

    # handle dhcp_server_identifier
    if test_num in dhcp_server_cases:
        ip_addr = 'DHCP_SERVER_IP'
        if 'host_ipv4_addr' in test_args:
            ip_addr = test_args['host_ipv4_addr']
        test_args['dhcp_server_identifier'] = ip_addr


def configure_test(args):
    import shutil
    import stat
    import ipaddr
    test = TEST_DEFINE['tests'][str(args.test)]
    out = 'Configuring for Test {0} - {1[name]}'.format(args.test, test)
    logger.info(out)
    test_args = {}

    # update ip_cidr and mac_address, CLI args take precendence
    if 'ip_cidr' in DUT_CONFIG:
        ip_address = ipaddr.IPv4Network(DUT_CONFIG['ip_cidr'])
        test_args['ip_cidr'] = DUT_CONFIG['ip_cidr']

    if args.ip_cidr:
        ip_address = ipaddr.IPv4Network(args.ip_cidr)
        test_args['ip_cidr'] = args.ip_cidr

    if 'mac_address' in DUT_CONFIG:
        test_args['mac_address'] = DUT_CONFIG['mac_address']

    if args.mac_address:
        test_args['mac_address'] = args.mac_address

    test_args['interface'] = args.interface
    test_args['hostname'] = 'testDUT'
    test_args['ip_address'] = ip_address.ip
    test_args['test_num'] = args.test
    test_args['test'] = test

    # make dir 'test-#'
    # for each required-service in test
    #    create all dirs from DEFAULT_DIRS
    #    make config file from DEFAULT_CONF_FILENAME
    #    call build_config(OUTPUT, test_args)
    #    close file
    #    make start script file from DEFAULT_CMD_BINARY exisitence
    #         filename is module.sh
    #    call build_cmd(OUTPUT, test_args)
    #    close file
    test_dir = 'test-{0}'.format(args.test)
    test_dir = os.path.join(os.path.abspath(args.output_dir), test_dir)
    test_args['test_dir'] = test_dir
    # Set various roots for modules that implement multiple services
    # i.e. dnsmasq.  This elimates running module confg in a particular order
    test_args['www_root'] = os.path.join(test_dir, 'www-root')
    test_args['tftp_root'] = os.path.join(test_dir, 'tftp-root')
    # dict of scripts by service
    test_args['scripts'] = {}

    # update options, CLI args take precendence
    if 'options' in DUT_CONFIG:
        test_args.update(DUT_CONFIG['options'])

    if args.option is not None:
        test_args.update(args.option)

    # check to see if we need onie_installer or onie_updater
    test_args['test_filename'] = None
    if test['action'] == 'installer':
        if 'onie_installer' not in test_args:
            logger.critical('Missing onie_installer option')
            sys.exit(-3)
        else:
            test_args['test_filename'] = test_args['onie_installer']
    if test['action'] == 'updater':
        if 'onie_updater' not in test_args:
            logger.critical('Missing onie_updater option')
            sys.exit(-3)
        else:
            test_args['test_filename'] = test_args['onie_updater']

    if args.disable_checks:
        logger.info('Skipping network config checks')
    else:
        validate_network_info(test_args)

    prepare_test_case(test_args)

    if os.path.exists(test_dir):
        # if file, remove it
        if os.path.isfile(test_dir):
            os.remove(test_dir)
        # if dir, remove it all
        if os.path.isdir(test_dir):
            shutil.rmtree(test_dir)

    os.makedirs(test_dir)
    for rqd_mod in test['required-services']:
        logger.debug('Handling {0} module'.format(rqd_mod))
        if rqd_mod not in LOADED_MODULES:
            logger.critical('Service {0} is not loaded'.format(rqd_mod))
            sys.exit(-1)
        else:
            mod = LOADED_MODULES[rqd_mod]
            for d in mod.DEFAULT_DIRS:
                dir_name = os.path.join(test_dir, d)
                if not os.path.exists(dir_name) and \
                   not os.path.isdir(dir_name):
                    os.mkdir(dir_name)

            # Determine if we are a dns module
            # if so, set enable_dns
            # Determine if dhcp server is not enabled or dnsmasq is not
            # dhcp server, if so set only_dns
            if rqd_mod == 'dns':
                logger.debug('Enabling DNS flag')
                test_args['enable_dns'] = True
                dns_service = TEST_DEFINE['available-services']['dns']
                dhcp_service = TEST_DEFINE['available-services']['dhcp']
                if 'dhcp' not in test['required-services'] or \
                   dns_service != dhcp_service:
                    logger.debug('Enabling ONLY_DNS flag')
                    test_args['only_dns'] = True

            # Determine if we are a tftp module
            # if so, check if we are dnsmasq
            # if so, set the enable_tftp flag in test_args
            if rqd_mod == 'tftp':
                tftp_service = TEST_DEFINE['available-services']['tftp']
                if tftp_service == 'dnsmasq':
                    test_args['enable_tftp'] = True

            # Determine if we need to save the path for some modules
            # i.e. dnsmasq
            copy_dir = None
            if rqd_mod in ['http', 'tftp']:
                copy_dir = True

            # copy installer/updater file if rqd_mod is http or tftp
            if copy_dir:
                if rqd_mod == 'http':
                    path = test_args['www_root']
                elif rqd_mod == 'tftp':
                    path = test_args['tftp_root']
                new_filename = test_case_file_name(test_args)
                if new_filename is not None:
                    dst_filename = os.path.join(path, new_filename)
                else:
                    basename = os.path.basename(test_args['test_filename'])
                    dst_filename = os.path.join(path, basename)
                shutil.copyfile(test_args['test_filename'], dst_filename)

            if mod.DEFAULT_CONF_FILENAME is not None:
                conf_filename = os.path.join(test_dir,
                                             mod.DEFAULT_CONF_FILENAME)
                conf_file = open(conf_filename, 'w')
                mod.build_config(conf_file, test_args)
                conf_file.close()

            if mod.DEFAULT_CMD_BINARY is not None:
                script_filename = os.path.join(test_dir,
                                               '{0}.sh'.format(rqd_mod))
                script_file = open(script_filename, 'w')
                mod.build_cmd(script_file, test_args)
                script_file.close()
                stat_res = os.stat(script_filename)
                os.chmod(script_filename, stat_res.st_mode | stat.S_IXGRP |
                         stat.S_IXOTH | stat.S_IXUSR)
                test_args['scripts'][rqd_mod] = script_filename

    return test_args


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Test ONIE")
    parser.add_argument('-c', '--config', action='store', metavar='CONFIG',
                        default=os.path.join('config', 'onie-tests.json'),
                        help='ONIE test definitions')
    parser.add_argument('-d', '--dut-config', action='store', metavar='CONFIG',
                        default=None,
                        help='DUT configuration file')
    parser.add_argument('-D', '--dump', action='store_true',
                        default=False,
                        help='Dump configs and scripts but do not execute')
    parser.add_argument('-i', '--ip-cidr', action='store',
                        metavar='CIDR',
                        default=None,
                        help='IP Address in CIDR format for DUT')
    parser.add_argument('-I', '--interface', action='store',
                        help='Interface to bind against')
    parser.add_argument('-l', '--list', action='store_true', default=False,
                        help='list all tests')
    parser.add_argument('-m', '--mac-address', action='store', metavar='MAC',
                        default=None,
                        help='MAC address of DUT')
    parser.add_argument('--disable-checks', action='store_true', default=False,
                        help='Disable all Network checks. '
                             'Useful when running on another machine.')
    parser.add_argument('-t', '--test', action='store', metavar='TEST NUM',
                        default=None,
                        help='ONIE test number to execute')
    parser.add_argument('-v', '--verbose', action='store_true',
                        default=False,
                        help='increase the verbosity level')
    parser.add_argument('-o', '--option', nargs='+',
                        metavar='KEY VALUE',
                        help='{0}Current options are: [{1}]'.
                        format('Set additional options, space separated.\n',
                               ' '.join(PRETTY_OPTIONS)))
    parser.add_argument('-O', '--output-dir', action='store', metavar='DIR',
                        default=DEFAULT_OUTPUT_DIR,
                        help='output director (default: {0})'.
                        format(DEFAULT_OUTPUT_DIR))

    args = parser.parse_args()
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    fmt_str = '%(asctime)s - %(levelname)s - %(message)s'
    formatter = logging.Formatter(fmt_str, '%Y-%m-%dT%H:%M:%S')
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    logger.setLevel(logging.INFO)

    if args.verbose:
        ch.setLevel(logging.DEBUG)
        logger.setLevel(logging.DEBUG)
    load_tests(args.config)
    # Load the required modules for processing
    load_modules()

    if args.list:
        list_tests()
        sys.exit(0)

    if args.test is None:
        logger.critical('Test number not given')
        parser.print_help()
        sys.exit(-1)

    if validate_test_num(args.test) is False:
        logger.critical('Invalid Test number')
        parser.print_help()
        sys.exit(-1)

    if args.interface is None:
        logger.critical('Interface is not given')
        parser.print_help()
        sys.exit(-1)

    if args.dut_config is not None:
        load_dut_config(args.dut_config)

    if args.mac_address is None and 'mac_address' not in DUT_CONFIG:
        logger.critical('No DUT MAC Address given')
        parser.print_help()
        sys.exit(-1)

    if args.ip_cidr is None and 'ip_cidr' not in DUT_CONFIG:
        logger.critical('No DUT CIDR given')
        parser.print_help()
        sys.exit(-1)

    if args.option is not None and len(args.option) != 0:
        if len(args.option) % 2 == 1:
            logger.critical('Not all options have a value')
            parser.print_help()
            sys.exit(-1)
        i = iter(args.option)
        args.option = dict(zip(i, i))
        validate_options(args.option)

    if args.mac_address and validate_mac_address(args.mac_address) is False:
        fixed_mac = fix_mac_address(args.mac_address)
        if fixed_mac is None:
            logger.critical('Invalid MAC Address')
            sys.exit(-1)
        args.mac_address = fixed_mac

    if args.ip_cidr and validate_ip_cidr(args.ip_cidr) is False:
        logger.critical('Invalid CIDR for DUT')
        sys.exit(-1)

    test_args = configure_test(args)

    if args.dump is False:
        import psutil
        ordered_services = ['tftp', 'http', 'dns', 'dhcp']
        running_procs = {}
        scripts = test_args['scripts']
        for svc in ordered_services:
            if svc in scripts:
                logger.info('Starting {0}'.format(svc))
                logger.debug(scripts[svc])
                proc = psutil.Popen(['bash', scripts[svc]])
                running_procs[svc] = proc
        # wait on user input
        try:
            raw_input('\n\nPress enter to stop all services\n\n')
        except:
            pass

        for svc, proc in running_procs.iteritems():
            logger.info('Sending SIGTERM to {0}'.format(svc))
            child_procs = proc.children(recursive=True)
            for p in child_procs:
                psutil.Popen('sudo kill -9 {0}'.format(p.pid), shell=True)
            proc.terminate()

        for svc, proc in running_procs.iteritems():
            logger.info('Waiting for {0} to cleanup'.format(svc))
            proc.wait()


if __name__ == "__main__":
    main()
