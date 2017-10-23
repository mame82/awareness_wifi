#!/usr/bin/python
from subprocess import Popen, PIPE
import BaseHTTPServer
import re
import posixpath
import urllib
import os
import mimetypes
import shutil
import urlparse

lport       = 9090
lhost = "10.0.0.1"


class CaptivePortal(BaseHTTPServer.BaseHTTPRequestHandler):
	wwwroot="var/www/"
	portalpage="portal.php"
	
	if not mimetypes.inited:
		mimetypes.init() # try to read system mime.types
	extensions_map = mimetypes.types_map.copy()
	extensions_map.update({
		'': 'application/octet-stream', # Default
		'.py': 'text/plain',
		'.c': 'text/plain',
		'.h': 'text/plain',
		})

	
	def getClientIP(self):
		return self.client_address[0]
		
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
	
	#this is the index of the captive portal
	#it simply redirects the user to the to login page
	html_redirect = """
	<html><head>
		<meta http-equiv="refresh" content="0; url=http://%s:%s/login" />
	</head>
	<body><b>Redirecting ...</b></body></html>
	"""%(lhost, lport)
	
	def guess_type(self, path):
		"""Guess the type of a file.

		Argument is a PATH (a filename).

		Return value is a string of the form type/subtype,
		usable for a MIME Content-type header.

		The default implementation looks the file's extension
		up in the table self.extensions_map, using application/octet-stream
		as a default; however it would be permissible (if
		slow) to look inside the data to make a better guess.

		"""

		base, ext = posixpath.splitext(path)
		if ext in self.extensions_map:
			return self.extensions_map[ext]
		ext = ext.lower()
		if ext in self.extensions_map:
			return self.extensions_map[ext]
		else:
			return self.extensions_map['']


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
	
	def sendPortalPage(self):
		path = self.translate_path(self.portalpage)
	
		ctype = self.guess_type(path) # determine mimetype based on extension
		
		try:
			f = open(path, 'rb')
		except IOError:
			self.send_response(200)
			self.send_header("Content-type", "text/html")
			self.end_headers()
			self.wfile.write(self.html_redirect)
			return
			
		self.send_response(200)
		self.send_header("Content-type", ctype)
		fs = os.fstat(f.fileno())
		self.send_header("Content-Length", str(fs[6]))
		self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
		self.end_headers()

		if f:
			self.copyfile(f, self.wfile)
			f.close()
	
	def do_GET(self):
		path = self.translate_path(self.path)

		f = None
		try:
			# Always read in binary mode. Opening files in text mode may cause
			# newline translations, making the actual size of the content
			# transmitted *less* than the content-length!
			f = open(path, 'rb')
		except IOError:
			print "File %s not found, sending portal page"%(path)
			self.sendPortalPage()
			return
		
		ctype = self.guess_type(path) # determine mimetype based on extension		
		# print "MimeType detected: %s"%(ctype)

		self.send_response(200)
		self.send_header("Content-type", ctype)
		fs = os.fstat(f.fileno())
		self.send_header("Content-Length", str(fs[6]))
		self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
		self.end_headers()

		# send file content
		self.copyfile(f, self.wfile)
		f.close()

	def copyfile(self, source, outputfile):
		shutil.copyfileobj(source, outputfile)

	def do_POST(self):
		# conditions for activation of client:
		#	target url: redirect.php
		#	parameters: fire=""
		
			
		self.send_response(200)
		self.send_header("Content-type", "text/html")
		self.end_headers()
		
		length = int(self.headers.getheader('content-length'))
		field_data = self.rfile.read(length)
		fields = urlparse.parse_qs(field_data)

		if "redirect.php" in self.path:
			if "fire" in fields:
				mac = self.getMacFromARPCache(self.getClientIP())
				if len(mac) > 0:
					print "Granting access for %s"%(mac)
		
		#print fields
		# form = cgi.FieldStorage(
			# fp=self.rfile, 
			# headers=self.headers,
			# environ={'REQUEST_METHOD':'POST',
					 # 'CONTENT_TYPE':self.headers['Content-Type'],
					 # })
		# username = form.getvalue("uname")
		# password = form.getvalue("pword")
		
		# if username == 'testuser' and password == 'pass1234':
			# remote_IP = self.client_address[0]
			# print 'New authorization from '+ remote_IP
			# print 'Updating IP tables'
			# subprocess.call(["iptables","-t", "nat", "-I", "PREROUTING","1", "-s", remote_IP, "-j" ,"ACCEPT"])
			# subprocess.call(["iptables", "-I", "FORWARD", "-s", remote_IP, "-j" ,"ACCEPT"])
			# self.wfile.write("You are now authorized. Navigate to any URL")
		# else:
			# self.sendPortalPage()
		
	#the following function makes server produce no output
	#comment it out if you want to print diagnostic messages
	#def log_message(self, format, *args):
	#    return

httpd = BaseHTTPServer.HTTPServer(('', lport), CaptivePortal)

try:
	httpd.serve_forever()
except KeyboardInterrupt:
	pass
httpd.server_close()
