// Generated by CoffeeScript 1.3.3
(function() {

  require({
    baseUrl: 'js',
    paths: {
      jquery: 'lib/jquery-1.8.2',
      jqueryui: 'lib/jquery-ui-1.9.0.custom.min',
      underscore: 'lib/underscore',
      backbone: 'lib/backbone-min',
      amplify: 'lib/amplify',
      mustache: 'lib/requirejs.mustache',
      base64: 'lib/base64',
      moment: 'lib/moment',
      xml2json: 'lib/jquery.xml2json',
      text: 'lib/text',
      domReady: 'lib/domReady',
      json: 'lib/json2',
      loader: 'lib/heartcode-canvasloader',
      swfobject: 'lib/swfobject'
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
      }
    }
  });

  require(['jquery', 'underscore', 'backbone', 'WorkspaceController', 'domReady', 'xml2json'], function($, _, Backbone, WorkspaceController, domReady) {
    return domReady(function() {
      if ($.fn.xml2json === void 0) {
        require(["xml2json"], function(xml2json) {
          return console.log(xml2json);
        });
      }
      window.workspace = WorkspaceController;
      return window.workspace.init();
    });
  });

}).call(this);
