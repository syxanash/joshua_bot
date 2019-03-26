from picamera import PiCamera
from time import sleep

camera = PiCamera()
camera.resolution = (2592, 1944)
sleep(1)
camera.capture('temp_photo.jpg')
