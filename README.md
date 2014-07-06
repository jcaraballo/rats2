rats
====

![Travis badge](https://travis-ci.org/jcaraballo/rats.svg?branch=master)


Battleships game, just to play a bit

The interaction is via a web service that allows to

### Create a game

    $ curl -X POST  localhost:8080/games
    {"resource": "/games/1"}

### Add players

    $ curl -X PUT --data '{"board": [[1, 1], [1, 2]], "callback": "http://localhost:990/shots"}' localhost:8080/games/1/players/bob
    {"resource": "/games/1/players/bob"}
