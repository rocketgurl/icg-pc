({
    appDir: "../",
    baseUrl: "js",
    dir: "../../build",
    mainConfigFile: 'main.js',
    paths : {
      jquery      : 'lib/jquery-1.8.2',
      underscore  : 'lib/underscore',
      backbone    : 'lib/backbone-min',
      amplify     : 'lib/amplify',
      mustache    : 'lib/requirejs.mustache',
      base64      : 'lib/base64',
      moment      : 'lib/moment',
      momentrange : 'lib/moment-range'
      xml2json    : 'lib/jquery.xml2json',
      text        : 'lib/text',
      domReady    : 'lib/domReady',
      json        : 'lib/json2',
      loader      : 'lib/heartcode-canvasloader',
      swfobject   : 'lib/swfobject',
      u_string    : 'lib/underscore.string'
    },
    shim: {
      'jquery': {
        deps: ['require'],
        exports: '$'
      },
      'xml2json': {
        deps: ['jquery']
      },
      'json': {
        deps: ['jquery'],
        exports: 'JSON'
      },
      'amplify': {
        deps: ['jquery', 'json'],
        exports: 'amplify'
      },
      'loader': {
        deps: ['jquery'],
        exports: 'CanvasLoader'
      },
      'swfobject': {
        deps: ['require'],
        exports: 'swfobject'
      },
      'u_string': {
        deps: ['underscore']
      }
    },
    modules: [
        {
            name: "main",
            exclude: [
              "swfobject"
            ]
        },
        {
            name : "modules/Policy/PolicyModule",
            exclude: [
                "jquery",
                "backbone",
                "mustache",
                "amplify",
                "underscore"
            ]
        },
        {
            name : "modules/Search/SearchModule",
            exclude: [
                "jquery",
                "backbone",
                "mustache",
                "amplify",
                "underscore",
                "swfobject"
            ]
        },
        {
            name : "modules/TestModule",
            exclude: [
                "jquery",
                "backbone",
                "mustache",
                "amplify",
                "underscore",
                "swfobject"
            ]
        },
        {
            name : "modules/ReferralQueue/ReferralQueueModule",
            exclude: [
                "jquery",
                "backbone",
                "mustache",
                "amplify",
                "underscore"
            ]
        }
    ],
    preserveLicenseComments: false
})