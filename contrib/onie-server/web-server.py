
#  Copyright (C) 2013 Daniel Walton <dwalton76@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0

import http.server
import socketserver
import sys

if (len(sys.argv) <= 1):
    sys.stderr.write("You must specify an IP address for the web server " \
                     "to run on\n")
    exit()

inside_ip = sys.argv[1]
web_port = 80
Handler = http.server.SimpleHTTPRequestHandler

try:
    httpd = socketserver.TCPServer((inside_ip, web_port), Handler)
except:
    sys.stderr.write("We were unable to start the web server. Normally when " \
                     "this happens it is because there is some other process " \
                     "that is already listening on port 80.\n")
else:
    httpd.serve_forever()
