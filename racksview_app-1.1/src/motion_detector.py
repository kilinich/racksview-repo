#!/usr/bin/env python3

from asyncio.log import logger
import datetime
import sys
import serial
import argparse
from collections import deque
import time
import os
import logging

logging.basicConfig(level=logging.INFO)

def read_distance():
    parser = argparse.ArgumentParser(description="Read distance from ultrasonic sensor via serial port.")
    parser.add_argument('--port', type=str, default='/dev/serial0', help='Serial device name (default: /dev/serial0)')
    parser.add_argument('--baud', type=int, default=115200, help='Baud rate (default: 115200)')
    parser.add_argument('--average', type=int, default=5, help='Time in seconds (default: 5) to average the distance readings')
    parser.add_argument('--jitter', type=int, default=50, help='Jitter value (default: 50) indicated motion detected')
    parser.add_argument('--distance', type=int, default=350, help='Minimum distance (default: 350) to consider motion undetected')
    parser.add_argument('--flag', type=str, default='/tmp/motion.flg', help='Name for motion flags (default: /tmp/motion.flg)')
    parser.add_argument('--unflag', type=str, default='/tmp/no-motion.flg', help='Name for no motion flags (default: /tmp/no-motion.flg)')
    parser.add_argument('--dump',  type=str, default='/dev/shm/mdetector.txt', help='Name for dump file (default: /dev/shm/mdetector.txt)')

    args, _ = parser.parse_known_args()

    # Check for incorrect values
    if args.baud < 110:
        logging.error("Baud rate must be 110 or greater.")
        sys.exit(1)
    if args.average < 1:
        logging.error("Average window must be a positive number.")
        sys.exit(1)
    if args.jitter < 1:
        logging.error("Jitter value must be a positive integer.")
        sys.exit(1)
    if args.distance < 20:
        logging.error("Distance value must be at least 20.")
        sys.exit(1) 

    # Delete old flag files on start
    for flag_file in [args.flag, args.unflag]:
        try:
            if os.path.exists(flag_file):
                os.remove(flag_file)
        except Exception as e:
            logging.error(f"Could not remove flag file {flag_file}: {e}")

    try:
        ser = serial.Serial(
            port=args.port,
            baudrate=args.baud,
            timeout=10
        )
    except serial.SerialException as e:
        logging.error(f"Error opening serial port {args.port}: {e}")
        sys.exit(1)
    
    try:
        buffer = deque([0, 0, 0, 0], maxlen=4)
        distances = deque(maxlen=1000)
        timestamps = deque(maxlen=1000)
        init_time = time.time()
        motion_status = "initializing"
        while True:
            byte = ser.read(1)
            if not byte:
                logging.error("No data received from serial port within timeout")
                sys.exit(2)

            buffer.append(byte[0])
            if buffer[0] == 0xFF:
                start_byte, data_h, data_l, checksum = buffer
                # Check if the checksum matches and you have a complete packet
                if checksum == (start_byte + data_h + data_l) & 0x00FF:
                    # Check for co-frequency interference (0xFFFE)
                    if data_h == 0xFF and data_l == 0xFE:
                        logging.error("Co-frequency interference detected")
                        continue
                    # Check for no object detected (0xFFFD)
                    if data_h == 0xFF and data_l == 0xFD:
                        distances.append(0)
                    else:
                        distances.append((data_h << 8) + data_l)
                    timestamps.append(time.time())
                    # Remove old values outside the averaging window, but always keep the latest value
                    while len(distances) > 1 and time.time() - timestamps[0] > args.average:
                        timestamps.popleft()
                        distances.popleft()
                    # Exclude zero values from averaging
                    nonzero_distances = [d for d in distances if d != 0]
                    if nonzero_distances:
                        avg_distance = int(round(sum(nonzero_distances) / len(nonzero_distances)))
                        values_in_window = len(nonzero_distances)
                    else:
                        avg_distance = 0
                        values_in_window = 0
                    # Calculate jitter (standard deviation of distances in the window)
                    if len(nonzero_distances) > 1:
                        variance = sum((d - avg_distance) ** 2 for d in nonzero_distances) / len(nonzero_distances)
                        jitter = int(round(variance ** 0.5))
                    else:
                        jitter = 0
                    # Determine if the reading is stable or unstable
                    nonzero_ratio = len(nonzero_distances) / len(distances) if distances else 0
                    debug_info = f"{datetime.datetime.now().strftime('%H:%M.%S')} dist={distances[-1]} avg={avg_distance} jitter={jitter} values={values_in_window} measured={round(nonzero_ratio*100)}%"
                    if time.time() - init_time < args.average:
                        motion_status = "initializing"
                    elif (jitter < args.jitter and avg_distance < args.distance and nonzero_ratio >= 1/3):
                        # Motion undetected
                        if motion_status == "detected":
                            # Flag switching from detected to undetected
                            with open(args.unflag, "w") as unflag_file:
                                unflag_file.write(f"flag undetected {debug_info}")
                                unflag_file.flush()
                        motion_status = "undetected"
                    else:
                        # Motion detected
                        if os.path.exists(args.unflag):
                            os.remove(args.unflag)
                        if motion_status == "undetected" or motion_status == "initializing":
                            with open(args.flag, "w") as flag_file:
                                flag_file.write(f"flag detected {debug_info}")
                                flag_file.flush()
                        motion_status = "detected"
                    # Write to dump file
                    with open(args.dump, "w") as dump_file:
                        dump_file.write(f"{motion_status} {debug_info}")
                        dump_file.flush()
    except KeyboardInterrupt:
        logging.info("Keyboard interrupt received, exiting gracefully.")
    except Exception as e:
        logging.error(f"Error during serial read: {e}")
    finally:
        ser.close()

if __name__ == "__main__":
    read_distance()
