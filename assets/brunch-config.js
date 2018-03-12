exports.config = {
  files: {
    javascripts: {
      joinTo: {
        'js/app.js': /^(js)(\/|\\)|(node_modules)/,
        'js/vendor.js': /^(vendor)(\/|\\)(?!Framework7)/
      },
      //
      // To change the order of concatenation of files, explicitly mention here
      // https://github.com/brunch/brunch/tree/master/docs#concatenation
      order: {
        before: [
          'vendor/jquery-2.1.4.min.js',
          'vendor/bootstrap-3.3.6-dist/js/bootstrap.js'
        ]
      }
    },
    stylesheets: {
      joinTo: {
        'css/app.css': /^css/,
        'css/framework7.css': 'node_modules/framework7/dist/css/framework7.css',
        'css/framework7-keypad.css': 'node_modules/framework7-plugin-keypad/dist/framework7.keypad.css',
        'css/bootstrap.css': /^(vendor\/bootstrap-3.3.6-dist\/css)/
      }
    },
    templates: {
      joinTo: 'js/app.js'
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
    styles: {
      framework7: ['dist/css/framework7.css'],
      'framework7-plugin-keypad': ['dist/framework7.keypad.css']
    },
    enabled: true
  }
};
