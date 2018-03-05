import $ from './$';
import * as Methods from './methods';
import * as Scroll from './scroll';
import * as Animate from './animate';
import * as eventShortcuts from './event-shortcuts';

[Methods, Scroll, Animate, eventShortcuts].forEach((group) => {
  Object.keys(group).forEach((methodName) => {
    $.fn[methodName] = group[methodName];
  });
});

export default $;
