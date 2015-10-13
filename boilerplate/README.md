# Nick's Boilerplate

If I have to create a new website, I start with this repository.

## Features

### Basics

* Flow-Router
* React
* Bootstrap
* SASS
* Simple-Schema
* Simple Security
* Internationalization

### Accounts

* Authentication pages based on bootstrap
* Main template handles authentication
* Facebook and google authentication configurable via settings.json

### Admin

* The admin page is a simple react component, customizable at will

### Utilities

* Alerts based on sAlert
* A global Constants object
* Pre-filled settings.example.json (settings.json is ignored)
* Admin and test user created at first startup
* SSL
* React utilities for flexible forms creation
* Various utilities

### Routes

* /
* /register
* /login
* /logout
* /account
* /admin

## Getting started

Clone this repository

Rename the "origin" remote to "boilerplate"

Enter the `platform` folder

Rename `settings.example.json` to `settings.json` and adapt.

Adapt the `lib/constants.coffee` file.

Start meteor:

    meteor --settings config/settings.json

## TODOS

* Breadcrumbs
* Mark active page in nav
* SQL

Author: Nicola Marcacci Rossi
Site: nmr.io
