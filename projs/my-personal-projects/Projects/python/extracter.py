#!/bin/python3


import re


def strip_comma_from_number(input_line):
    new_line = re.sub(r'(\d+),(\d+)', r'\1\2', input_line)
    return new_line


def do_it():
    input_l = '"ddr-da-alphaPinCheck",brishty,"87,641"'
    new_line = strip_comma_from_number(input_l)
    print(new_line)


do_it()
