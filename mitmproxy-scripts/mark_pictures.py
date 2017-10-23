from io import BytesIO
from PIL import Image, ImageDraw, ImageFont, ImageEnhance
from mitmproxy import ctx

FONT = './mitmproxy-scripts/Arial-bold.ttf'

def add_watermark( in_img, angle=23, opacity=0.25):
    text = "M&M\n(Markus & Marcus)"
    img = in_img.convert('RGBA')
    watermark = Image.new('RGBA', img.size, (0,0,0,0))
    size = 2
    n_font = ImageFont.truetype(FONT, size)
    n_width, n_height = n_font.getsize(text)
    while n_width+n_height < watermark.size[0]:
        size += 2
        n_font = ImageFont.truetype(FONT, size)
        n_width, n_height = n_font.getsize(text)
    draw = ImageDraw.Draw(watermark, 'RGBA')
    draw.text(((watermark.size[0] - n_width) / 2,
              (watermark.size[1] - n_height) / 2),
              text, font=n_font, fill=(255,0,0,255))
    watermark = watermark.rotate(angle,Image.BICUBIC)
    alpha = watermark.split()[3]
    alpha = ImageEnhance.Brightness(alpha).enhance(opacity)
    watermark.putalpha(alpha)
    return Image.composite(watermark, img, watermark)
    
def response( flow):
	ctx.log.info("content type -------------------")
	ctx.log.info(flow.response.headers.get("content-type", ""))
	if flow.response.headers.get("content-type", "").startswith("image"):
				s = BytesIO(flow.response.content)
				img = Image.open(s).convert('LA').transpose(Image.FLIP_TOP_BOTTOM)
				img = add_watermark(img,45, 0.85)
				s2 = BytesIO()
				img.save(s2, "png")
				flow.response.content = s2.getvalue()
				flow.response.headers["content-type"] = "image/png"
				ctx.log.info("Watermark placed")
				ctx.log.info("=====================")

