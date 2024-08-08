#!/usr/bin/python3
# COMP3311 24T2 Assignment 2
# Written by William Kim (z5348193) on 7/30/2024
# Print a list of countries where a named movie was released

import sys
import psycopg2
import helpers

### Globals
db = None
usage = f"Usage: {sys.argv[0]} 'MovieName' Year"
### Command-line args
if len(sys.argv) < 3:
   print(usage)
   exit(1)
# process the command-line args 
movie_name = sys.argv[1]
year = sys.argv[2]
if  not (year.isdigit()) and len(year) == 4:
   print("Invalid year")
   exit(1)
year = int(year)
### Queries
# Get the movie id and its origin country
queryMovieExistence  = """
SELECT m.id, c.name as origin_country
FROM movies m
LEFT JOIN countries c ON m.origin = c.code
WHERE m.title = %s AND m.year = %s;
"""
# Get the countries where the movie was released
queryMovieReleases = """
SELECT c.name
FROM releasedin r
JOIN countries c ON r.country = c.code
WHERE r.movie = %s;
"""
### Manipulating database
try:
   db = psycopg2.connect("dbname=ass2")
   cursor = db.cursor()
   # Check if the movie exists
   cursor.execute(queryMovieExistence, (movie_name, year))
   movie = cursor.fetchone()
   if not movie:
      print("No such movie")
      exit(1)
   movie_id, origin_country = movie
   # Check the releases of the movie
   cursor.execute(queryMovieReleases, (movie_id,))
   releases = cursor.fetchall()
   if not releases:
      print("No releases")
      exit(1)
   release_countries = [country[0] for country in releases]
   if len(release_countries) == 1 and release_countries[0] == origin_country:
      print(f"The movie was only released in its origin country: {origin_country}")
   else:
      for country in sorted(release_countries):
         print(country)
except Exception as err:
   print("DB error: ", err)
finally:
   if db:
      db.close()

