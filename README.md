# The curious case of EventStore/EventStore#1468

Steps to reproduce:

1. `docker-compose up --force-recreate`
2. Let the script run for a minute or so, then quit using Control+C
2. `docker-compose up`
2. Open http://localhost:2113/web/index.html#/projections

Good luck.
