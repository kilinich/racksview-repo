#!/usr/bin/env python3

import sys
import argparse
import serial
import time
import binascii

def crc16_modbus(data):
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            if crc & 0x0001:
                crc = (crc >> 1) ^ 0xA001
            else:
                crc = crc >> 1
    return crc

def main():
    parser = argparse.ArgumentParser(description="Send hex string to serial port repeatedly.")
    parser.add_argument("--port", default="/dev/serial0", help="Serial port (e.g., COM3 or /dev/ttyUSB0)")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate (default: 115200)")
    args = parser.parse_args()

    hex_str = "01 06 02 01 00 03 99 B3"
    data = bytes.fromhex(hex_str)

    try:
        ser = serial.Serial(args.port, baudrate=args.baud, timeout=1)
    except Exception as e:
        print(f"Error opening serial port: {e}")
        sys.exit(1)

    print(f"Sending to {args.port}: {hex_str}")
    while True:
        ser.write(data)
        time.sleep(0.1)
        response = ser.read(ser.in_waiting or 1)
        if response:
            print("Received:", ' '.join(f"{b:02X}" for b in response))

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting on Ctrl-C.")
        sys.exit(0)