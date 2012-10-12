require
  baseUrl: 'js'
  paths: 
    jquery     : 'lib/jquery-1.8.2'
    jqueryui   : 'lib/jquery-ui-1.9.0.custom.min'
    underscore : 'lib/underscore-min'
    backbone   : 'lib/backbone-min'
    amplify    : 'lib/amplify'
    mustache   : 'lib/requirejs.mustache'
    base64     : 'lib/base64'
    xml2json   : 'lib/jquery.xml2json'
    text       : 'lib/text'
    domReady   : 'lib/domReady'
    json       : 'lib/json2'
    loader     : 'lib/heartcode-canvasloader'
    swfobject  : 'lib/swfobject'
  priority: ['jquery']
  shim:
      'jquery' : 
        deps    : ['require']
        exports : '$' 
      'json' : 
        deps    : ['jquery']
        exports : 'JSON'
      'amplify' :
        deps    : ['jquery', 'json']
        exports : 'amplify'
      'loader' :
        deps    : ['jquery']
        exports : 'CanvasLoader'
      'xml2json' : ['jquery'],
      'swfobject' :
        deps    : ['require']
        exports : 'swfobject' 

define [
  'jquery',
  'underscore',
  'backbone',
  'WorkspaceController',
  'UserModel',
  'ConfigModel',
  'WorkspaceStateModel',
  'WorkspaceStateCollection',
  'WorkspaceLoginView',
  'WorkspaceCanvasView',
  'WorkspaceNavView',
  'WorkspaceRouter',
  'modules/Search/SearchContextCollection',
  'Messenger',
  'base64',
  'MenuHelper',
  'AppRules',
  'Helpers',
  'Cookie',
  'domReady',
  'xml2json'
], ($, _, Backbone, WorkspaceController, UserModel, ConfigModel, WorkspaceStateModel, WorkspaceStateCollection, WorkspaceLoginView, WorkspaceCanvasView, WorkspaceNavView, WorkspaceRouter, SearchContextCollection, Messenger, Base64, MenuHelper, AppRules, Helpers, Cookie, domReady) ->

  # Initialize application when dom is ready
  domReady ->
    # Oh yes we did! Attached WorkspaceController to the window,
    # because it makes debugging a helluva lot easier.
    window.workspace = WorkspaceController
    window.workspace.init()
    