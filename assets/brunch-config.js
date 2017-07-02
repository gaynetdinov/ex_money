exports.config = {
  files: {
    javascripts: {
      joinTo: {
        "js/app.js": /^(js)(\/|\\)|(node_modules)/,
        "js/vendor.js": /^(vendor)(\/|\\)(?!Framework7)/,
        "js/framework7.js": /^(vendor\/Framework7\/)/,
        "js/mobile.js": /^(vendor\/Framework7_custom\/js)/
      },
      //
      // To change the order of concatenation of files, explicitly mention here
      // https://github.com/brunch/brunch/tree/master/docs#concatenation
      order: {
        before: [
          "vendor/jquery-2.1.4.min.js",
          "vendor/bootstrap-3.3.6-dist/js/bootstrap.js",
          "vendor/Framework7/js/framework7.js",
          "vendor/Framework7/js/framework7.keypad.js"
        ]
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": /^(css)(\/|\\)(?!mobile)/,
        "css/vendor.css": /^(vendor)(\/|\\)(?!Framework7)|(deps)/,
        "css/framework7.css": /^(vendor\/Framework7\/)/,
        "css/mobile.css": /^(vendor\/Framework7_custom\/css)/
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
