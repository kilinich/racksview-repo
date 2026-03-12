#!/usr/bin/env python3

import board
import busio
import adafruit_ssd1306
from PIL import Image, ImageDraw, ImageFont
import socket
from datetime import datetime
import uuid

# Initialize I2C and OLED
i2c = busio.I2C(board.SCL, board.SDA)
oled = adafruit_ssd1306.SSD1306_I2C(128, 64, i2c, addr=0x3c)

# Load a Monospaced font
font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
font = ImageFont.truetype(font_path, 10)

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def get_mac():
    mac_num = hex(uuid.getnode()).replace('0x', '').upper()
    mac_num = mac_num.zfill(12)
    return ':'.join(mac_num[i: i + 2] for i in range(0, 11, 2))

def get_hostname():
    return socket.gethostname()

def update_display():
    # 1. Clear / Create Image buffer
    image = Image.new("1", (oled.width, oled.height))
    draw = ImageDraw.Draw(image)

    # 2. Gather data
    hostname_str = get_hostname()
    ip_str = get_ip()
    mac_str = get_mac()
    dt_str = datetime.now().strftime("%Y-%m-%d %H:%M")

    # 3. Draw lines centered
    # 8 lines fit in 64px, so each line is ~8px high. Our font is size 10.
    # We have 4 lines, total height ~ 44px. 
    # Center vertically: (64 - 44) // 2 = 10
    lines = [hostname_str, ip_str, mac_str, dt_str]
    y_start = 10
    y_step = 11

    for i, line in enumerate(lines):
        line_w = draw.textlength(line, font=font)
        x = (oled.width - line_w) // 2
        y = y_start + (i * y_step)
        draw.text((x, y), line, font=font, fill=255)

    # 4. Push to hardware
    oled.image(image)
    oled.show()

# Run once for testing
if __name__ == "__main__":
    update_display()