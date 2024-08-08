#!/usr/bin/python3
# COMP3311 24T2 Assignment 2
# Written by William Kim (z5348193) on 7/30/2024
# Print a list of countries where a named movie was released

import sys
import psycopg2
import helpers

### Globals
db = None
usage = f"Usage: {sys.argv[0]} Year"
### Command-line args
if len(sys.argv) < 2:
   print(usage)
   exit(1)
year = sys.argv[1]
# process the command-line args ...
if not year.isdigit() or len(year) != 4:
   print("Invalid year")
   exit(1)
### Queries
query = """
   SELECT g.genre, AVG(m.rating) AS avg_rating
   FROM movies m
   JOIN moviegenres g ON m.id = g.movie
   WHERE m.year = %s
   GROUP BY g.genre
   ORDER BY avg_rating DESC, g.genre
   LIMIT 10;
   """
### Manipulating database
try:
   db = psycopg2.connect("dbname=ass2")
   cursor = db.cursor()
   # your code goes here
   cursor.execute(query, (year,))
   results = cursor.fetchall()
   if not results:
      print("No movies")
   else:
      # Average Rating with 2 decimal places
      for genre, avg_rating in results:
         print(f"{avg_rating:.2f} {genre}")
except Exception as err:
   print("DB error: ", err)
finally:
   if db:
      db.close()

