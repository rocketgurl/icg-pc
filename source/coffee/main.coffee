require
  baseUrl: 'js'
  paths: 
    jquery     : 'lib/jquery-1.8.2'
    jqueryui   : 'lib/jquery-ui-1.9.0.custom.min'
    underscore : 'lib/underscore'
    backbone   : 'lib/backbone-min'
    amplify    : 'lib/amplify'
    mustache   : 'lib/requirejs.mustache'
    base64     : 'lib/base64'
    moment     : 'lib/moment'
    xml2json   : 'lib/jquery.xml2json'
    text       : 'lib/text'
    domReady   : 'lib/domReady'
    json       : 'lib/json2'
    loader     : 'lib/heartcode-canvasloader'
    swfobject  : 'lib/swfobject'
  priority: ['jquery','xml2json','json']
  shim:
      'jquery' : 
        deps    : ['require']
        exports : '$'
      'xml2json' : 
        deps : ['jquery']
      'json' : 
        deps    : ['jquery']
        exports : 'JSON'
      'amplify' :
        deps    : ['jquery', 'json']
        exports : 'amplify'
      'loader' :
        deps    : ['jquery']
        exports : 'CanvasLoader'
      'swfobject' :
        deps    : ['require']
        exports : 'swfobject' 

require [
  'jquery',
  'underscore',
  'backbone',
  'WorkspaceController',
  'domReady',
  'xml2json'
], ($, _, Backbone, WorkspaceController, domReady) ->

  # Initialize application when dom is ready
  domReady ->
    # Oh yes we did! Attached WorkspaceController to the window,
    # because it makes debugging a helluva lot easier.
    window.workspace = WorkspaceController
    window.workspace.init()
    