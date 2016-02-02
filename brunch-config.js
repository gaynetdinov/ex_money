exports.config = {
  files: {
    javascripts: {
      joinTo: {
        "js/app.js": /^(web\/static\/js)(\/|\\)(?!mobile)/,
        "js/vendor.js": /^(web\/static\/vendor)(\/|\\)(?!Framework7)|(deps)/,
        "js/framework7.js": /^(web\/static\/vendor\/Framework7\/)/,
        "js/mobile.js": /^(web\/static\/vendor\/Framework7_custom\/js)/
      },
      //
      // To change the order of concatenation of files, explicitly mention here
      // https://github.com/brunch/brunch/tree/master/docs#concatenation
      order: {
        before: [
          "web/static/vendor/jquery-2.1.4.min.js",
          "web/static/vendor/bootstrap-3.3.6-dist/js/bootstrap.js",
          "web/static/vendor/Framework7/js/framework7.min.js",
          "web/static/vendor/Framework7/js/framework7.keypad.js"
        ]
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": /^(web\/static\/css)(\/|\\)(?!mobile)/,
        "css/vendor.css": /^(web\/static\/vendor)(\/|\\)(?!Framework7)|(deps)/,
        "css/framework7.css": /^(web\/static\/vendor\/Framework7\/)/,
        "css/mobile.css": /^(web\/static\/vendor\/Framework7_custom\/css)/
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/web/static/assets". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(web\/static\/assets)|^(web\/static\/vendor\/Framework7\/img)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "deps/phoenix/web/static",
      "deps/phoenix_html/web/static",
      "web/static",
      "test/static"
    ],

    // Where to compile files to
    public: "priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/web\/static\/vendor/]
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["web/static/js/app"]
    }
  },

  npm: {
    enabled: true
  }
};
