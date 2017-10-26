#!/usr/bin/python
from subprocess import Popen, PIPE
import BaseHTTPServer
import re
import posixpath
import urllib
import os
import mimetypes
import urlparse
import sys
import base64
import getopt
import signal

def sigterm_handler(_signo, _stack_frame):
    # Raises SystemExit(0), to catch finally block of main Thread
    sys.exit(0)

class IPTablesIF(object):
	cpchain_name = "portalchain"
	lhost = "10.0.0.1"
	lport = 9090
	hotspotif = "wlan1"
		
	def __init__(self):
		print "IPTable deleting former captive portal rules"
		self.clear_chains()
		print "IPTable adding new captive portal rules"
		self.setup_portal_chain()
	
	def exec_comand(self, command):
		p = Popen(command.split(" "), stdin=PIPE, stdout=PIPE, stderr=PIPE)
		output, err = p.communicate()
		
		res = output + err
		
		return res
		
	def clear_chains(self):
		self.exec_comand("iptables -t mangle -F %s"%(self.cpchain_name)) # flush portal chain
		self.exec_comand("iptables -t mangle -D PREROUTING -j %s"%(self.cpchain_name)) # remove portal chain from prerouting
		self.exec_comand("iptables -t mangle -X %s"%(self.cpchain_name)) # delete portal chain
		self.exec_comand("iptables -t nat -D PREROUTING -m mark --mark 99 -p tcp --dport 80 -j REDIRECT --to-port " + str(self.lport))
		self.exec_comand("iptables -t filter -D FORWARD -m mark --mark 99 -j DROP")
		
	def check_if_mac_allowed(self, mac):
		if len(mac) > 0:
			res=self.exec_comand("iptables -t mangle -L %s"%(self.cpchain_name))
			if mac in res:
				# already present
				return True
			else:
				# not present
				return False
		else:
			return True # we return true to avoid taking the decission to add an empty MAC
		
		
	def remove_allowed_mac(self, mac):
		if len(mac) > 0:
			self.exec_comand("iptables -t mangle -D %s -m mac --mac-source %s -j RETURN"%(self.cpchain_name, mac))
		
	def add_allowed_mac(self, mac):
		if len(mac) > 0:
			if not self.check_if_mac_allowed(mac):
				self.exec_comand("iptables -t mangle -I %s -m mac --mac-source %s -j RETURN"%(self.cpchain_name, mac))
		
	def setup_portal_chain(self):
		# check if basic rule have been applied
		print "setup captive portal redirect firewall rules"

		# create chain for captive portal in mangle
		self.exec_comand("iptables -t mangle -N " + self.cpchain_name)
		#redirect packets from mangle prerouting to  portal_chain
		self.exec_comand("iptables -t mangle -A PREROUTING -j " + self.cpchain_name)
		#mark all packets in mangle portal_chain with 99 (eception rules will be added by captive portal later on)
		self.exec_comand("iptables -t mangle -i " + self.hotspotif + " -A " + self.cpchain_name + " -j MARK --set-mark 99")

		#redirect http requests marked with 99 to CP
		self.exec_comand("iptables -t nat -I PREROUTING 1 -m mark --mark 99 -p tcp --dport 80 -j REDIRECT --to-port " + str(self.lport))

		#drop marked packets which aren't directed to port 80 
		self.exec_comand("iptables -t filter -A FORWARD -m mark --mark 99 -j DROP")

class CaptivePortal(BaseHTTPServer.BaseHTTPRequestHandler):
	wwwroot="var/www/"
	portalpage="index.html"
	placeholder_prefix = "placeholder_"
	default_page="www.bing.com"
	iptif = None

	lport       = 9090
	lhost = "10.0.0.1"
	
	generate404 = ['/success.txt']
	generate302 = ['/generate_204']
	
	# define additional mimetypes
	if not mimetypes.inited:
		mimetypes.init() # try to read system mime.types
	extensions_map = mimetypes.types_map.copy()
	extensions_map.update({
		'': 'application/octet-stream', # Default
		'.py': 'text/plain',
		'.c': 'text/plain',
		'.h': 'text/plain',
		})


	def exec_comand(self, command):
		p = Popen(command.split(" "), stdin=PIPE, stdout=PIPE, stderr=PIPE)
		output, err = p.communicate()
		
		res = output + err
		
		return res
	
	def findPlaceholder(self, text):
		res = re.findall(self.placeholder_prefix + "[a-zA-Z0-9_-]*", text)
		
		# remove doubles
		res = list(set(res))
		
		# remove prefix
		res = [ r.replace(self.placeholder_prefix, "") for r in res ]
		
		return res
		
	def substitutePlaceholder(self, placeholderName, value, text):
		return text.replace(self.placeholder_prefix + placeholderName, value)

	# get client IP out of current request
	def getClientIP(self):
		return self.client_address[0]
		
	# resolve IP to MAC from ARP cache
	def getMacFromARPCache(self, ip):
		p = Popen(['arp', '-a', ip], stdin=PIPE, stdout=PIPE, stderr=PIPE)
		output, err = p.communicate()
		
		mac = ""
		
		try:
			# grab only first hit (group 0)
			mac = re.search(r"..:..:..:..:..:..", output).group(0)
		except TypeError:
			# no string in output
			pass
		except AttributeError:
			# no match ... group(0) tries to access NoneType
			pass
		
		return mac
	
	
	# try to determine mimetype based on extension of given path (no content inspection)
	def guess_type(self, path):
		base, ext = posixpath.splitext(path)
		if ext in self.extensions_map:
			return self.extensions_map[ext]
		ext = ext.lower()
		if ext in self.extensions_map:
			return self.extensions_map[ext]
		else:
			return self.extensions_map['']


	# translate given URI path to file path
	def translate_path(self, path):
		"""Translate a /-separated PATH to the local filename syntax.

		Components that mean special things to the local file system
		(e.g. drive or directory names) are ignored.  (XXX They should
		probably be diagnosed.)

		"""
		# abandon query parameters
		path = path.split('?',1)[0]
		path = path.split('#',1)[0]
		path = posixpath.normpath(urllib.unquote(path))
		words = path.split('/')
		words = filter(None, words)
		path = os.getcwd() + "/" + self.wwwroot
		for word in words:
			drive, word = os.path.splitdrive(word)
			head, word = os.path.split(word)
			if word in (os.curdir, os.pardir): continue
			path = os.path.join(path, word)
		return path
	
	# prepare HTTP response
	def send_response(self, code, message=None):
		"""Send the response header and log the response code.

		Also send two standard headers with the server software
		version and the current date.

		"""
		self.log_request(code)
		if message is None:
			if code in self.responses:
				message = self.responses[code][0]
			else:
				message = ''
		if self.request_version != 'HTTP/0.9':
			self.wfile.write("%s %d %s\r\n" %
							 (self.protocol_version, code, message))
			# print (self.protocol_version, code, message)
		# self.send_header('Server', self.version_string())
		# self.send_header('Date', self.date_time_string())
		self.send_header('Server', "Captive Portal by MaMe82")
	
	
	def respond302(self, host, port="", uri=""):
		if len(str(port)) > 0:
			port = ":" + str(port)
		resp = """
		<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
		<html><head>
		<title>302 Found</title>
		</head><body>
		<h1>Found</h1>
		<p>The document has moved <a href="http://%s%s%s">here</a>.</p>
		</body></html>
		"""%(host, port, uri)
	
		self.send_response(302)
		self.send_header("Content-type", "text/html")
		self.send_header("Content-Length", str(len(resp)))
		self.send_header("Location", "http://%s%s%s"%(host, port, uri))
		self.send_header("Connection", "close")
		self.end_headers()
		self.wfile.write(resp)
	
	def respond404(self):
		self.send_response(404)
		self.send_header("Connection", "close")
		self.end_headers()
		
	# send PortalPage as response
	def sendPortalPage(self):
		path = self.translate_path(self.portalpage)
	
		ctype = self.guess_type(path) # determine mimetype based on extension
		
		try:
			f = open(path, 'rb')
			t = self.parseFile(f)
		except IOError:
			self.respond404()
			return
		
			
			
		self.send_response(200)
		self.send_header("Content-type", ctype)
		fs = os.fstat(f.fileno())
		self.send_header("Content-Length", str(len(t)))
		self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
		self.end_headers()

		self.wfile.write(t)
		f.close()
			

	def parseFile(self, f):
		client_ip = self.getClientIP()
		client_mac = self.getMacFromARPCache(client_ip)
				
		t = f.read()
		placeholders = self.findPlaceholder(t)
		
		print "=============================="
		print "Fetched palceholders:"
		print placeholders
		print "=============================="
		
		

		if "clientmac_b64" in placeholders:
			t = self.substitutePlaceholder("clientmac_b64", base64.b64encode(client_mac), t)
		if "client_ip" in placeholders:
			t = self.substitutePlaceholder("client_ip", client_ip, t)
		return t

	# handle GET requests
	def do_GET(self):
		path = self.translate_path(self.path)

		if self.path in self.generate404:
			print "Generating 404 for %s"%(self.path)
			self.respond404()
			return

		if os.path.isdir(path):
			print "=========================================================="
			print "File %s not found 302 redirecting to portal page"%(path)
			print self.headers
			print "=========================================================="
			self.respond302(self.lhost, self.lport, "/"+self.portalpage)
			return

		f = None
		try:
			f = open(path, 'rb')
			t = self.parseFile(f)
			
		except IOError:
			print "=========================================================="
			print "File %s not found 302 redirecting to portal page"%(path)
			print self.headers
			print "=========================================================="
			self.respond302(self.lhost, self.lport, "/"+self.portalpage)
			return
			
		ctype = self.guess_type(path) # determine mimetype based on extension		
		# print "MimeType detected: %s"%(ctype)

		self.send_response(200)
		self.send_header("Content-type", ctype)
		fs = os.fstat(f.fileno())
		self.send_header("Content-Length", str(len(t)))
		self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
		self.end_headers()

		# send file content
		
		
		self.wfile.write(t)
		f.close()
		
	def do_POST(self):
		# conditions for activation of client:
		#	target url: redirect.php
		#	parameters: fire=""
		
			
		contentlength = self.headers.getheader('content-length')
		length = 0
		if contentlength:
			length = int(contentlength)
		field_data = self.rfile.read(length)
		fields = urlparse.parse_qs(field_data)

		if "placeholder_grant_access" in self.path:
			if "fire" in fields:
				mac = self.getMacFromARPCache(self.getClientIP())
				if len(mac) > 0:
					print "Granting access for %s"%(mac)
					self.iptif.add_allowed_mac(mac)
					self.respond302(self.default_page)
					return

		self.do_GET()

		#self.send_response(200)
		#self.send_header("Content-type", "text/html")
		#self.end_headers()


def main(argv):
	lhost = "10.0.0.1"
	lport = 9090
	hotspotif = "wlan1"
	
	try:
		opts, args = getopt.getopt(argv, "i:h:p:", ["interface=", "host=", "port="])
	except getopt.GetoptError:
		usage()
		sys.exit(2)

	for opt, arg in opts:
		if opt in ("-i", "--interface"):
			hotspotif = arg
		elif opt in ("-h", "--host"):
			lhost = arg
			
			
		elif opt in ("-p", "--port"):
			lport = int(arg)
			

	IPTablesIF.hotspotif = hotspotif
	IPTablesIF.lhost = lhost
	IPTablesIF.lport = lport
	CaptivePortal.lport = lport
	CaptivePortal.lhost = lhost
	CaptivePortal.iptif = IPTablesIF() # do it here, as we don't have an __init__ function
	
	httpd = BaseHTTPServer.HTTPServer(('', lport), CaptivePortal)
	
	httpd.RequestHandlerClass.timeout = 2 # set timeout for arriving requests to 2000ms second

	try:
		httpd.serve_forever()
	except KeyboardInterrupt:
		pass
	finally:
		print "Deleting IPTables rules"
		IPTablesIF.clear_chains(CaptivePortal.iptif)
	httpd.server_close()

if __name__ == "__main__":
	if len(sys.argv) < 1:
		print "to few arguments"
		sys.exit()
	signal.signal(signal.SIGTERM, sigterm_handler)
	main(sys.argv[1:])
