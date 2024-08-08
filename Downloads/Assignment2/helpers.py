# COMP3311 24T2 Assignment 2 ... Python helper functions
# add here any functions to share between Python scripts 
# you must submit this even if you add nothing

import re

# check whether a string looks like a year value
# return the integer value of the year if so

def getYear(year):
   digits = re.compile("^\d{4}$")
   if not digits.match(year):
      return None
   else:
      return int(year)


# List of movies written by person
