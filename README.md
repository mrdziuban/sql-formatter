# SQL Formatter

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Setup](#setup)
  - [Dart](#dart)
  - [ElixirScript](#elixirscript)
  - [Elm](#elm)
  - [ES6](#es6)
  - [GopherJS](#gopherjs)
  - [Opal](#opal)
  - [PHP.js](#phpjs)
  - [PureScript](#purescript)
  - [Rust](#rust)
  - [Scala.js](#scalajs)
- [Development](#development)
  - [Compile](#compile)
    - [Compile certain languages](#compile-certain-languages)
  - [Run](#run)
  - [Test](#test)
  - [Build for production](#build-for-production)
- [Deployment](#deployment)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

This is a simple SQL formatter that handles formatting whitespace and capitalization of keywords. I originally wrote
it for the purpose of learning Elm, but it soon became a project where I could try out languages that I'm
unfamiliar with and see how many different languages can be compiled down to JavaScript. Most of the languages used,
plus a lot of others, can be
[found here](https://github.com/jashkenas/coffeescript/wiki/list-of-languages-that-compile-to-js).

The app logic in each language is compiled to JavaScript using various Webpack loaders,
[some of which I implemented as wrappers around shell commands](https://github.com/mrdziuban?utf8=%E2%9C%93&tab=repositories&q=-loader&type=&language=).
The current languages are:

- [Dart](#dart)
- [ElixirScript](#elixirscript)
- [Elm](#elm)
- [ES6](#es6)
- [GopherJS](#gopherjs)
- [Opal](#opal)
- [PHP.js](#phpjs)
- [PureScript](#purescript)
- [Rust](#rust)
- [Scala.js](#scalajs)

Check it out at [http://mattdziuban.com/sql-formatter/](http://mattdziuban.com/sql-formatter/).

![demo](https://cloud.githubusercontent.com/assets/4718399/22834351/d7d838ee-ef82-11e6-8556-ef36db229229.gif)

## Setup

Install npm dependencies first with `npm install`, then follow the steps for each language below.

### Dart

[Find the correct Dart SDK URL for the desired version and OS here](https://www.dartlang.org/install/archive),
then run the following:

```bash
mkdir -p "$HOME/.dart"
curl -L <dart-sdk-url> -o "$HOME/.dart/dart.zip"
unzip -q "$HOME/.dart/dart.zip" -d "$HOME/.dart"
export PATH="$HOME/.dart/dart-sdk/bin:$PATH"
pub get
```

### ElixirScript

First, install Erlang and Elixir. On Mac, you can install Erlang with `brew install erlang`. To install Elixir, I
recommend using [Kiex](https://github.com/taylor/kiex).

Then install ElixirScript:

```bash
export EXS_VERSION=56cb2c5
mkdir -p "$HOME/.elixirscript/$EXS_VERSION"
curl -o- -L https://s3.amazonaws.com/mrdziuban-resources/elixirscript-$EXS_VERSION.tar.gz -o "$HOME/.elixirscript/elixirscript-$EXS_VERSION.tar.gz" | tar xvzf - -C "$HOME/.elixirscript/$EXS_VERSION"
export PATH="$HOME/.elixirscript/$EXS_VERSION/dist/elixirscript/bin:$PATH"
```

### Elm

Install Elm packages:

```bash
$(npm bin)/elm-package install
```

### ES6

The ES6 build doesn't require any additional dependencies!

### GopherJS

First, [install Go 1.8](https://golang.org/dl/), then run:

```bash
go get -u github.com/gopherjs/gopherjs
```

### Opal

First, install Ruby if you don't already have it. I recommend using [RVM](https://rvm.io/). Then run:

```bash
bundle install
```

### PHP.js

Install PHP (any version 5.3-5.6 should work fine), then install PHPUnit:

```bash
mkdir -p "$HOME/.phpunit/bin"
curl -sL https://phar.phpunit.de/phpunit-4.8.phar -o "$HOME/.phpunit/bin/phpunit"
chmod +x "$HOME/.phpunit/bin/phpunit"
export PATH="$HOME/.phpunit/bin:$PATH"
```

### PureScript

Install bower dependencies:

```bash
$(npm bin)/bower install
```

### Rust

Rust has the most experimental compilation process, using
[support for Emscripten via nightly builds](https://users.rust-lang.org/t/compiling-to-the-web-with-rust-and-emscripten/7627).
First, make sure you have cmake installed, then run:

```bash
# Install Rust
curl -L https://sh.rustup.rs | sh -s -- -y --default-toolchain=nightly
source ~/.cargo/env
rustup target add asmjs-unknown-emscripten

# Install the Emscripten SDK
mkdir -p "$HOME/.emsdk"
curl -o- -L https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz | tar xvzf - -C "$HOME/.emsdk"
source "$HOME/.emsdk/emsdk_portable/emsdk_env.sh"
emsdk update
# This step will take a bit
emsdk install sdk-incoming-64bit
emsdk activate sdk-incoming-64bit
```

### Scala.js

Run the following to setup SBT:

```bash
export SBT_VERSION=0.13.13
mkdir -p "$HOME/.sbt-bin/$SBT_VERSION"
curl -o- -L https://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz | tar xvzf - -C "$HOME/.sbt-bin/$SBT_VERSION" --strip-components 1
export PATH="$HOME/.sbt-bin/$SBT_VERSION/bin:$PATH"
```

## Development

### Compile

Compile all code to JavaScript:

```bash
npm run compile
```

#### Compile certain languages

The `compile` command accepts comma-separated `only` and `exclude` arguments to filter what languages are compiled,
e.g.

```bash
# Only compile ES6 and Opal
npm run compile -- --env.only es6,opal

# Compile everything but GopherJS and Dart
npm run compile -- --env.exclude gopherjs,dart
```

### Run

Run the Webpack dev server:

```bash
npm run dev
```

*Note: The `dev` command also accepts the `only` and `exclude` arguments mentioned above*

Then visit [http://localhost:8000](http://localhost:8000) in your browser.

### Test

Tests are run using a variety tools to match the different languages. To run them:

```bash
npm run test
```

### Build for production

```bash
npm run dist
```

*Note: The `dist` command also accepts the `only` and `exclude` arguments mentioned above*

## Deployment

Deployment to GitHub pages is automated via Travis CI on builds on the master branch.
