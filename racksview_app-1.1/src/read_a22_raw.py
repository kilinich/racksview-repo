#!/usr/bin/env python3

import sys
import argparse
import serial
import time
import binascii

def main():
    parser = argparse.ArgumentParser(description="Send hex string to serial port repeatedly.")
    parser.add_argument("--port", default="/dev/serial0", help="Serial port (e.g., COM3 or /dev/ttyUSB0)")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate (default: 115200)")
    args = parser.parse_args()

    try:
        ser = serial.Serial(args.port, baudrate=args.baud, timeout=1)
    except Exception as e:
        print(f"Error opening serial port: {e}")
        sys.exit(1)

    while True:
        byte = ser.read(1)
        if byte:
            if byte[0] == 0xFF:
                print(f"\n{byte[0]:02X}", end=' ', flush=True)
            else:
                print(f"{byte[0]:02X}", end=' ', flush=True)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting on Ctrl-C.")
        sys.exit(0)