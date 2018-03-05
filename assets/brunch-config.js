exports.config = {
  files: {
    javascripts: {
      joinTo: {
        'js/app.js': /^(js)(\/|\\)|(node_modules)/,
        //'js/app.js': /^(js)/,
        //'js/mobile.js': /^node_modules\/framework7/
        //"js/vendor.js": /^(vendor)(\/|\\)(?!Framework7)/
        //"js/framework7.js": /^(vendor\/Framework7\/)/
        //"js/mobile.js": /^(vendor\/Framework7_custom\/js)/
      },
      //
      // To change the order of concatenation of files, explicitly mention here
      // https://github.com/brunch/brunch/tree/master/docs#concatenation
      order: {
        before: [
          //"node_modules/dom7/dist/dom7.modular.js"
          //"node_modules/template7/dist/template7.js",
          //"node_modules/framework7/dist/framework7.js"
          //"vendor/jquery-2.1.4.min.js",
          //"vendor/bootstrap-3.3.6-dist/js/bootstrap.js"
          //"vendor/Framework7/js/framework7.js",
          //"vendor/Framework7/js/framework7.keypad.js"
        ]
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": /^css/,
        //'css/mobile.css': /^node_modules\/framework7\/dist\/css/
        //"css/vendor.css": /^(vendor)(\/|\\)(?!Framework7)|(deps)/,
        //"css/framework7.css": /^(vendor\/Framework7\/)/,
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: ["static", "js", "css", "vendor"],

    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true
  }
};
