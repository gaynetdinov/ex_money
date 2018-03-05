<a href="https://www.patreon.com/vladimirkharlampidi"><img src="https://cdn.framework7.io/i/support-badge.png" height="20"></a>
[![devDependency Status](https://david-dm.org/nolimits4web/dom7/dev-status.svg)](https://david-dm.org/nolimits4web/dom7#info=devDependencies)

# Dom7

## Minimalistic JavaScript library for DOM manipulation, with a jQuery-compatible API

Dom7 - is the default DOM manipulation library built-in [Framework7](http://framework7.io). It utilizes most edge and high-performance methods for DOM manipulation. You don’t need to learn something new, its usage is very simple because it has the same syntax as well known jQuery library with support of the most popular and widely used methods and jQuery-like chaining.

See [Framework7 Dom7](http://framework7.io/docs/dom.html) documentation for usage examples and available methods.

## Build

You will need Node.js installed on your system.

First, install all required dependencies
```
$ npm install
```

To build development version:
```
$ npm run build-dev
```

The resulting files are:

  1. buid/dom7.js
  2. buid/dom7.module.js

To build production (minified) version:
```
$ npm run build-prod
```

The resulting files are:

  1. dist/dom7.js
  2. dist/dom7.min.js
  3. dist/dom7.module.js
