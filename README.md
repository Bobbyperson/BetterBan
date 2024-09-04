# BetterBan

## Purpose

The Northstar Docker image recreates the R2Northstar folder on each startup, which contains banlist.txt. This mod essentially recreates and improves on the ability to ban players. You are able to send who is and isn't banned to an API via a custom version of laundmo's parseable logs.

## Features

1. Customizable ban message
2. Ability to ban by UID even when players are not on the server

## Setup and Usage

After adding admin ids and your ban message in `mod.json`, the commands are as follows:

- `bban <name>` - Only works with online players.
- `bunban <uid>`
- `bbanuid <uid>`
Commands run in console are the same but begin with `c`. For example `cbban`

## Todo

- [x] Allow for console to run these commands
- [ ] Publish to Thunderstore