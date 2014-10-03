var allTestFiles = [];
var TEST_REGEXP = /(spec|test)\.js$/i;

var pathToModule = function (path) {
  return path.replace(/^\/base\//, '../').replace(/\.js$/, '');
};

Object.keys(window.__karma__.files).forEach(function(file) {
  if (TEST_REGEXP.test(file)) {

    // Normalize paths to RequireJS module names.
    allTestFiles.push(pathToModule(file));
  }
});

require.config({
  // Karma serves files under /base, which is the basePath from your config file
  baseUrl: '/base/js',

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
    text: 'lib/text',
    domReady: 'lib/domReady',
    json: 'lib/json2',
    loader: 'lib/heartcode-canvasloader',
    swfobject: 'lib/swfobject',
    u_string: 'lib/underscore.string',
    u_policycentral: 'underscore.policycentral',
    herald: 'lib/herald/herald',
    marked: 'lib/marked',
    chosen: 'lib/chosen.jquery',
    Apparatchik: 'lib/Apparatchik',
    favicon: 'lib/favicon',
    transition: 'lib/bootstrap/transition',
    tab: 'lib/bootstrap/tab',
    collapse: 'lib/bootstrap/collapse',
    button: 'lib/bootstrap/button',
    tooltip: 'lib/bootstrap/tooltip',
    popover: 'lib/bootstrap/popover'
  },
  priority: ['jquery', 'xml2json', 'json'],
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
    'momentrange': {
      deps: ['moment']
    },
    'chosen': {
      deps: ['jquery'],
      exports: 'Chosen'
    },
    'Apparatchik': {
      deps: ['jquery', 'underscore', 'moment']
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
    }
  },

  // dynamically load all test files
  deps: allTestFiles,

  // we have to kickoff jasmine, as it is asynchronous
  callback: window.__karma__.start
});
