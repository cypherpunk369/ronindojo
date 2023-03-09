#!/usr/bin/env python

import RP64.GPIO as GPIO

var_gpio_ron = 12
var_gpio_red = 15

GPIO.setwarnings(True)
GPIO.setmode(GPIO.BOARD)
GPIO.setup(var_gpio_ron, GPIO.OUT, initial=GPIO.HIGH)
GPIO.setup(var_gpio_red, GPIO.OUT, initial=GPIO.LOW)
GPIO.cleanup([var_gpio_red,var_gpio_ron])
