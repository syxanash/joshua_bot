# Complete Project Details: https://RandomNerdTutorials.com/raspberry-pi-bme280-data-logger/

import smbus2
import bme280
import sys

# BME280 sensor address (default address)
address = 0x76

# Initialize I2C bus
bus = smbus2.SMBus(1)

calibration_params = bme280.load_calibration_params(bus, address)

data = bme280.sample(bus, address, calibration_params)

temperature_celsius = data.temperature
humidity = data.humidity
pressure = data.pressure

# Print the readings
print("Temp={0:0.1f}ºC, Humidity={1:0.1f}%, Pressure={2:0.2f}hPa".format(temperature_celsius, humidity, pressure))