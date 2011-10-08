#!/bin/env python

#
# password_generator.py
#
# This script allows for generating random alpha-numeric passwords with an
# addition of common punctuation characters when needed.
#

import string
import random

class PasswordGenerator():

    def __init__(self, password_length=8):
        self.length = password_length if password_length > 8 else 8

    def generate(self, simple=False):
        # We build a character set depending on what is needed ...

        character_set = string.letters + string.digits \
                      + '' if simple else string.punctuation

        # Choose random characters from out set and concatenate together ...
        return ''.join([random.choice(character_set) for c in range(self.length)])

if __name__ == '__main__':
    print PasswordGenerator(32).generate(True)
