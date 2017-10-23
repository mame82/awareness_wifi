#!/usr/bin/python
import binascii
import sys
while sys.stdin:
	print binascii.b2a_base64(sys.stdin.readline().rstrip()) ,
	sys.stdout.flush()