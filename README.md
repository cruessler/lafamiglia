[![Build Status](https://github.com/cruessler/lafamiglia/workflows/build/badge.svg)](https://github.com/cruessler/lafamiglia/actions?query=workflow%3Abuild)

# La Famiglia

La Famiglia is a multiplayer browser game focusing on:

- simple game play,
- easily usable UI,
- diplomacy and the interaction between players.

Every player starts with a villa where they can construct buildings and recruit
units. As soon as they have units they can attack other players, plunder their
resources, and eventually conquer their villas.

The game itself is designed to be rather simple, making diplomacy the most
important and interesting part of it.

La Famiglia is developed in [Elixir](http://elixir-lang.org), using
[Phoenix](http://www.phoenixframework.org/).

## Status

Right now, La Famiglia is, in most parts, a tech preview exploring the
possibilities of Elixir and Phoenix. Some parts are already in good shape while
others are still more of a proof of concept.

## TODO

Among the things not yet implemented are:

- release management with [distillery](https://github.com/bitwalker/distillery)
  and [edeliver](https://github.com/boldpoker/edeliver),
- i18n,
- time zones.

## Installation

### First installation

Prerequisites: Erlang 20.0, Elixir 1.8, PostgreSQL 9.6 (these are the version
that are tested on CI as of May 2020).

- `git clone https://github.com/cruessler/lafamiglia.git`
- Copy sample configuration files:
```
    cd lafamiglia/config
    cp config.sample.exs config.exs
    cp prod.sample.exs prod.exs
    cp prod.secret.sample.exs prod.secret.exs
```
- Configure host and port in `config/prod.exs`.
  The sample config uses the env variable `PORT` for setting the port (useful if
  La Famiglia is supposed to run behind a proxy).
- Make Postgres listen on a TCP port (Ecto will not connect via unix socket).
- Prepare secrets and db configuration in `config/prod.secret.exs`.
  See http://www.phoenixframework.org/docs/deployment.
- `mix deps.get`
- `MIX_ENV=prod mix compile`
- `MIX_ENV=prod mix la_famiglia.postcompile`
- `MIX_ENV=prod mix ecto.create`
- `MIX_ENV=prod mix ecto.migrate`
- `npm install`
- `npm run deploy`
- `MIX_ENV=prod mix phoenix.digest`
- `PORT=$PORT MIX_ENV=prod mix la_famiglia.server`

### Upgrade

- Stop the server.
- `git pull`
- `mix deps.get` if necessary
- `MIX_ENV=prod mix compile`
- `MIX_ENV=prod mix la_famiglia.postcompile`
- `MIX_ENV=prod mix ecto.migrate` if necessary
- `npm install` if necessary
- `npm run deploy`
- `MIX_ENV=prod mix phoenix.digest`
- Restart the server.

## License

La Famiglia is distributed under the terms of the MIT license.
