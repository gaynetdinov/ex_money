# Change Log

## Dom7 v2.0.3 - Released on February 21, 2018
  * Fixed issue with not found `$.extend` in `.animate`

## Dom7 v2.0.2 - Released on February 10, 2018
  * Added `ssr-window` dependency to throw less errors in SSR environment

## Dom7 v2.0.1 - Released on October 2, 2017
  * Modular version `dom7.modular.js` is more modular now and exports every method separately.

## Dom7 v2.0.0 - Released on September 11, 2017
  * Removed XHR (Ajax) functionality
  * Removed `$.` utilities, including `$.parseUrlQuery`, `$.isArray`, `$.each`, `$.unique`, `$.serializeObject`, `$.dataset`, `$.extend`

## Dom7 v1.7.2 - Released on September 7, 2017
  * Fixed issue when calling `.show()` always set `display: block` not repsecting actual display property

## Dom7 v1.7.1 - Released on September 2, 2017
  * Removed `$.getTranslate` method
  * Imporved logic of `$.extend` method
  * New `dom7.modular.js` version for custom es imports, e.g. `import { $, Methods, Ajax } from 'dom7.modular.js'`

## Dom7 v1.7.0 - Released on August 30, 2017
  * New `.forEach((element, index))` method
  * New `.map((index, element))` method
  * New `.toArray()` method that converts Dom7 collection to simple array
  * `$.supportTouch` and `$.removeDiacritics` helpers removed
  * Fixed issue with detaching live event listener without listener function

## Dom7 v1.6.4 - Released on August 2, 2017
  * Fixed issue with handling events without target (e.g. Cordova "resume" event)
  * Fixed issue with Ajax post method throwing error with "multipart/form-data" content type

## Dom7 v1.6.3 - Released on May 30, 2017
  * Added shortcut methods `click blur focus focusin focusout keyup keydown keypress submit change mousedown mousemove mouseup mouseenter mouseleave mouseout mouseover touchstart touchend touchmove resize scroll`

## Dom7 v1.6.2 - Released on May 12, 2017
  * Proxified events. Now all events are being added/removed using proxy functions. This allows to pass additional arguments to events handlers and detach all assigned event listener by calling e.g. `$$(document).off('someEvent');`

## Dom7 v1.6.1 - Released on April 19, 2017
  * New `Dom7.extend(obj1, obj2, ...)` method
  * Added `.animate(props, params)` and `.stop()` animation methods
  * Added ES2015 module build
