# Mechanize [![Build Status](https://travis-ci.org/gushonorato/mechanize.svg?branch=master)](https://travis-ci.org/gushonorato/mechanize) [![Coverage Status](https://coveralls.io/repos/github/gushonorato/mechanize/badge.svg?branch=master)](https://coveralls.io/github/gushonorato/mechanize?branch=master)

Build web scrapers and automate interaction with websites in Elixir with ease! One of Mechanize's main design goals is to enable developers to easily create concurrent web scrapers without imposing any process architecture. Mechanize is heavily inspired on [Ruby](https://github.com/sparklemotion/mechanize) version of [Mechanize](https://metacpan.org/release/WWW-Mechanize). It features:

- Follow hyperlinks
- Scrape data easily using CSS selectors
- Populate and submit forms (WIP)
- Follow and tracks 3xx redirects
- Follow meta-refresh
- Automatically stores and sends cookies (TODO)
- File upload (TODO)
- Track of the sites that you have visited as a history (TODO)
- Proxy support (TODO)
- Obey robots.txt (TODO)

## Installation

> **Warning:** This library is in active development and probably will have changes in the public API. It is not currently recommended to use it on production systems.

The package can be installed by adding `mechanize` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mechanize, github: "gushonorato/mechanize"}
  ]
end
```

## Authors
Copyright © 2019 by Gustavo Honorato (gustavohonorato@gmail.com)

## License
This library is distributed under the MIT license. Please see the LICENSE file.
