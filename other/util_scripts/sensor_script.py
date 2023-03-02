from gpiozero import MotionSensor
import sys

def write_log(file_name, value):
    out_file = open(file_name, 'w')
    out_file.write(value)
    out_file.close()

if len(sys.argv) != 2:
    print("[!] please enter a output filename!")
    exit(1)

pir = MotionSensor(4)
filename = sys.argv[1]

write_log(filename, '0')

while True:
    pir.wait_for_motion()
    write_log(filename, '1')

    pir.wait_for_no_motion()
    write_log(filename, '0')
