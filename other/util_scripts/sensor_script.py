from gpiozero import MotionSensor
import sys

def write_log(file_name, value):
    out_file = open(file_name, 'w')
    out_file.write(value)
    out_file.close()

if len(sys.argv) != 2:
    print "[!] please enter a output filename!"
    exit(1)

pir = MotionSensor(4)

noticed = False
filename = sys.argv[1]

while True:
    if pir.motion_detected:
        if not noticed:
            write_log(filename, '1') 
            noticed = True
    else:
        write_log(filename, '')
        noticed = False
