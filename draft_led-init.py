#!/usr/bin/env python

# Importing required libraries
import RPi.GPIO as GPIO
import time

# Number of pin to which appropriate lines is connected
#P1 (RPi v1)
#   3V3  (1) (2)  5V
# GPIO2  (3) (4)  5V
# GPIO3  (5) (6)  GND
# GPIO4  (7) (8)  GPIO14
#   GND  (9) (10) GPIO15
#GPIO17 (11) (12) GPIO18
#GPIO27 (13) (14) GND
#GPIO22 (15) (16) GPIO23
#   3V3 (17) (18) GPIO24
#GPIO10 (19) (20) GND
# GPIO9 (21) (22) GPIO25
#GPIO11 (23) (24) GPIO8
#   GND (25) (26) GPIO7
pinRed = 11   # red LED    (GPIO 17)
pinGreen = 13 # green LED  (GPIO 27)
pinBlue = 15  # blue LED   (GPIO 22)

# Initializing GPIO environment
GPIO.setmode(GPIO.BOARD)
GPIO.setwarnings(False)

# Initializing GPIO ports
GPIO.setup(pinRed, GPIO.OUT)
GPIO.setup(pinGreen, GPIO.OUT)
GPIO.setup(pinBlue, GPIO.OUT)