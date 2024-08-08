#!/usr/bin/python3

# COMP3311 24T2 Assignment 2
# Written by William Kim (z5348193) on 7/30/2024
# Print a list of movies written by a given person

import sys
import psycopg2
import helpers

### Globals
db = None
usage = f"Usage: {sys.argv[0]} FullName"
if len(sys.argv) < 2:
   print(usage)
   exit(1)
# process the command-line args 
full_name = sys.argv[1]
### Queries
# Get the list of movies written by this person
query = """
SELECT m.title, m.year
FROM Movies m
JOIN principals p ON m.id = p.movie
WHERE p.person = %s AND p.job = 'writer'
ORDER BY m.year, m.title;
"""
### Manipulating database
try:
   db = psycopg2.connect("dbname=ass2")
   cursor = db.cursor()
   # Get the person ID
   cursor.execute("SELECT id FROM People WHERE name = %s", (full_name,))
   persons = cursor.fetchall()
   if not persons:
      print("No such person")
      sys.exit(1)
   # List to store movies
   movies = []
   # Fetch movies for each person ID
   for person in persons:
      person_id = person[0]
      cursor.execute(query, (person_id,))
      movies.extend(cursor.fetchall())
   # Print errors else movies
   if not movies:
      if len(persons) > 1:
         print(f"None of the people called {full_name} has written any films")
      else:
         print(f"{full_name} has not written any movies")
   else:
      for movie in movies:
         print(f"{movie[0]} ({movie[1]})")
except Exception as err:
   print("DB error: ", err)
finally:
   if db:
      cursor.close()
      db.close()
