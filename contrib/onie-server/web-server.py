
#  Copyright (C) 2013 Daniel Walton <dwalton76@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0

import SimpleHTTPServer
import SocketServer
import sys

if (len(sys.argv) <= 1):
    sys.stderr.write("You must specify an IP address for the web server " \
                     "to run on\n")
    exit()

inside_ip = sys.argv[1]
web_port = 80
Handler = SimpleHTTPServer.SimpleHTTPRequestHandler

try:
    httpd = SocketServer.TCPServer((inside_ip, web_port), Handler)
except:
    sys.stderr.write("We were unable to start the web server. Normally when " \
                     "this happens it is because there is some other process " \
                     "that is already listening on port 80.\n")
else:
    httpd.serve_forever()
