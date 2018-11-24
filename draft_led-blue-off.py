#!/usr/bin/env python

# Importing required libraries
import RPi.GPIO as GPIO
import time

execfile("./draft_led-settings.py")

# Initializing GPIO environment
GPIO.setmode(GPIO.BOARD)
GPIO.setwarnings(False)

# Initializing GPIO ports
GPIO.setup(pinBlue, GPIO.OUT)
GPIO.output(pinBlue, GPIO.LOW)