import document from './document';

let w;
if (typeof window === 'undefined') {
  w = {
    document,
    navigator: {
      userAgent: '',
    },
    location: {},
    history: {},
    CustomEvent: function CustomEvent() {
      return this;
    },
    addEventListener() {},
    removeEventListener() {},
    getComputedStyle() {
      return {
        getPropertyValue() {
          return '';
        },
      };
    },
    Image() {},
    Date() {},
    screen: {},
    setTimeout() {},
    clearTimeout() {},
  };
} else {
  // eslint-disable-next-line
  w = window;
}

const win = w;

export default win;
