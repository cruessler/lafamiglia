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

# Status

Right now, La Famiglia is, in most parts, a tech preview exploring the
possibilities of Elixir and Phoenix. Some parts are already in good shape while
others are still more proof of concept.

## TODO

Among the things not yet implemented are:

- occupying and conquering other players’ villas,
- i18n,
- time zones (currently all dates are saved and displayed as UTC; work on this
  is postponed until the release of Elixir 1.3 which will provide date and time
  types).

## Installation

### First installation

Prerequisites: Erlang 18, Elixir 1.2, PostgreSQL 9.4.

- `git clone https://github.com/cruessler/lafamiglia.git`
- Configure host and port in `config/prod.exs`.
  The sample config uses the env variable `PORT` for setting the port (useful if
  La Famiglia is supposed to run behind a proxy).
- Make Postgres listen on a TCP port (Ecto will not connect via unix socket).
- Prepare secrets and db configuration in `config/prod.secret.exs`.
  See http://www.phoenixframework.org/docs/deployment.
- `mix deps.get`
- `MIX_ENV=prod mix compile`
- `MIX_ENV=prod mix ecto.create`
- `MIX_ENV=prod mix ecto.migrate`
- `brunch build --production`
- `MIX_ENV=prod mix phoenix.digest`
- `npm install`
- `bower install`
- `PORT=$PORT HOST=$HOST MIX_ENV=prod mix la_famiglia.server`

### Upgrade

- Stop the server.
- `git pull`
- `mix deps.get` if necessary
- `MIX_ENV=prod mix compile`
- `MIX_ENV=prod mix ecto.migrate` if necessary
- `brunch build --production`
- `MIX_ENV=prod mix phoenix.digest`
- `bower install` if necessary
- Restart the server.

Currently, `exrm` cannot be used for release management as parts of La
Famiglia’s configuration are dynamic while `exrm` only works with static
configuration.

# License

La Famiglia is distributed under the terms of the MIT license.
