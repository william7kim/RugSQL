#!/usr/bin/python3

# COMP3311 24T2 Assignment 2
# Written by William Kim (z5348193) on 7/30/2024
# Print info about one movie; may need to choose

import sys
import psycopg2
import helpers

### Globals
db = None
usage = f"Usage: {sys.argv[0]} 'PartialMovieName'"
### Command-line args
if len(sys.argv) < 2:
   print(usage)
   exit(1)
# process the command-line args
partial_title = sys.argv[1]
### Queries
query_movies = """
SELECT id, title, year FROM movies WHERE title ILIKE %s ORDER BY title, year;
"""
# retrieve principals (actors, directors, and others) for a specific movie
query_principals = """
SELECT p.name, pr.job, COALESCE(r.role, '???') AS role
FROM principals pr
JOIN people p ON pr.person = p.id
LEFT JOIN playsrole r ON pr.id = r.inmovie
WHERE pr.movie = %s
ORDER BY pr.ord;
"""
### Manipulating database
try:
   db = psycopg2.connect("dbname=ass2")
   cur = db.cursor()
   # Find movies matching the partial title
   cur.execute(query_movies, ('%' + partial_title + '%',))
   movies = cur.fetchall()
   if not movies:
      print(f"No movie matching: '{partial_title}'")
      exit(1)
   # If exactly one movie is found, select it
   if len(movies) == 1:
      movie_id, title, year = movies[0]
   else:
      # If multiple movies are found, list them and prompt the user to select one
      for idx, (movie_id, title, year) in enumerate(movies, start=1):
         print(f"{idx}. {title} ({year})")
      choice = int(input("Which movie? ")) - 1
      movie_id, title, year = movies[choice]
   print(f"{title} ({year})")
   cur.execute(query_principals, (movie_id,))
   principals = cur.fetchall()
   # Print the name and role/job of each principal
   for name, job, role in principals:
      if job == 'actor' or job == 'actress' or job == 'self':
         print(f"{name} plays {role}")
      else:
         print(f"{name}: {job}")
except Exception as err:
   print("DB error: ", err)
finally:
   if db:
      db.close()
