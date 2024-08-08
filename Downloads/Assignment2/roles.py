#!/usr/bin/python3

# COMP3311 24T2 Assignment 2
# Written by William Kim (z5348193) on 7/30/2024
# Print a list of character roles played by an actor/actress

import sys
import psycopg2
import helpers

### Globals
db = None
usage = f"Usage: {sys.argv[0]} FullName"
### Command-line args
if len(sys.argv) < 2:
    print(usage)
    exit(1)
# Process the command-line args
full_name = " ".join(sys.argv[1:])
### Queries
# Query to get the person id and name
query1 = """
SELECT id, name FROM people
WHERE name = %s
ORDER BY id;
"""
# Query to get the roles played by the person from principals and playsrole
query2 = """
SELECT r.role, m.title, m.year, m.rating
FROM principals p
JOIN movies m ON p.movie = m.id
JOIN playsrole r ON p.id = r.inmovie
WHERE p.person = %s AND (p.job = 'actor' OR p.job = 'actress' OR p.job = 'self')
ORDER BY m.year, m.title, r.role;
"""
### Manipulating database
try:
    db = psycopg2.connect("dbname=ass2")
    cur = db.cursor()
    cur.execute(query1, (full_name,))
    people = cur.fetchall()
    if not people:
        print("No such person")
        exit(1)
    # Process for each person found
    for person_index, (person_id, person_name) in enumerate(people, start=1):
        cur.execute(query2, (person_id,))
        roles = cur.fetchall()
        if len(people) > 1:
            print(f"{person_name} #{person_index}")
        if not roles:
            print("No acting roles")
        else:
            for role, title, year, rating in roles:
                print(f"{role} in {title} ({year}) {rating:.1f}")
    cur.close()
except Exception as err:
    print("DB error: ", err)
finally:
    if db:
        db.close()
