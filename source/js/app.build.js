({
  appDir: "../",
  baseUrl: "js",
  dir: "../../build",
  mainConfigFile: 'main.js',
  paths: {
    jquery: 'lib/jquery-1.8.2',
    jqueryui: 'lib/jquery-ui-1.9.0.custom.min',
    underscore: 'lib/underscore',
    backbone: 'lib/backbone-min',
    amplify: 'lib/amplify',
    mustache: 'lib/requirejs.mustache',
    base64: 'lib/base64',
    moment: 'lib/moment',
    momentrange: 'lib/moment-range',
    xml2json: 'lib/jquery.xml2json',
    marked: 'lib/marked',
    text: 'lib/text',
    domReady: 'lib/domReady',
    json: 'lib/json2',
    herald: 'lib/herald/herald',
    loader: 'lib/heartcode-canvasloader',
    swfobject: 'lib/swfobject',
    chosen: 'lib/chosen.jquery',
    u_string: 'lib/underscore.string',
    u_policycentral: 'underscore.policycentral',
    Apparatchik : 'lib/Apparatchik',
    favicon: 'lib/favicon',
    transition: 'lib/bootstrap/transition',
    tab: 'lib/bootstrap/tab',
    collapse: 'lib/bootstrap/collapse',
    button: 'lib/bootstrap/button',
    tooltip: 'lib/bootstrap/tooltip',
    popover: 'lib/bootstrap/popover',
    dropdown: 'lib/bootstrap/dropdown'
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
    'underscore': {
      exports: '_'
    },
    'backbone': {
      deps: ['jquery', 'json', 'underscore']
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
    },
    'Apparatchik': {
      deps: ['jquery','underscore','moment']
    },
    'favicon': {
      exports: 'favicon'
    },
    'transition': {
      deps: ['jquery']
    },
    'tab': {
      deps: ['jquery']
    },
    'collapse': {
      deps: ['transition']
    },
    'popover': {
      deps: ['jquery', 'tooltip']
    },
    'dropdown': {
      deps: ['jquery']
    }
  },
  modules: [
    {
      name: "main",
      exclude: ["swfobject"]
    }, {
      name: "modules/Policy/PolicyModule",
      exclude: ["jquery", "backbone", "mustache", "amplify", "underscore"]
    }, {
      name: "modules/Search/SearchModule",
      exclude: ["jquery", "backbone", "mustache", "amplify", "underscore", "swfobject"]
    },{
      name: "modules/ReferralQueue/ReferralQueueModule",
      exclude: ["jquery", "backbone", "mustache", "amplify", "underscore", "swfobject"]
    }
  ],
  preserveLicenseComments: false,
  removeCombined: false,
  optimize: "uglify2",
  uglify2: {
    warnings: true,
    mangle: true
  }
})
