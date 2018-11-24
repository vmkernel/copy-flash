#!/usr/bin/env python

# Importing required libraries
import RPi.GPIO as GPIO
import time

./draft_led-settings.py

# Initializing GPIO environment
GPIO.setmode(GPIO.BOARD)
GPIO.setwarnings(False)

# Initializing GPIO ports
GPIO.setup(pinRed, GPIO.OUT)
GPIO.output(pinRed, GPIO.HIGH)