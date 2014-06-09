requirejs.config { waitSeconds: 0 }

require
  urlArgs: ''
  baseUrl: 'js'
  paths:
    jquery          : 'lib/jquery-1.8.2'
    jqueryui        : 'lib/jquery-ui-1.9.0.custom.min'
    underscore      : 'lib/underscore'
    backbone        : 'lib/backbone-min'
    amplify         : 'lib/amplify'
    mustache        : 'lib/requirejs.mustache'
    base64          : 'lib/base64'
    moment          : 'lib/moment'
    momentrange     : 'lib/moment-range'
    xml2json        : 'lib/jquery.xml2json'
    text            : 'lib/text'
    domReady        : 'lib/domReady'
    json            : 'lib/json2'
    loader          : 'lib/heartcode-canvasloader'
    swfobject       : 'lib/swfobject'
    u_string        : 'lib/underscore.string'
    u_policycentral : 'underscore.policycentral'
    herald          : 'lib/herald/herald'
    marked          : 'lib/marked'
    chosen          : 'lib/chosen.jquery'
    Apparatchik     : 'lib/Apparatchik'
    favicon         : 'lib/favicon'
    tab             : 'lib/bootstrap/tab'
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
      'u_string' :
        deps : ['underscore']
      'momentrange' :
        deps : ['moment']
      'chosen' :
        deps : ['jquery']
        exports : 'Chosen'
      'Apparatchik' :
        deps : ['jquery','underscore','moment']

require [
  'jquery',
  'underscore',
  'backbone',
  'WorkspaceController',
  'u_string',
  'u_policycentral',
  'domReady',
  'xml2json',
  'chosen'
], ($, _, Backbone, WorkspaceController, u_string, u_policycentral, domReady) ->

  # Setup underscore.string
  _.mixin _.str.exports()

    # Bring in Underscore Policy Central extensions
  _.mixin u_policycentral


  # Initialize application when dom is ready
  domReady ->
    if $.fn.xml2json == undefined
      require ["xml2json"], (xml2json) ->
        console.log xml2json


    # Oh yes we did! Attached WorkspaceController to the window,
    # because it makes debugging a helluva lot easier.
    window.workspace = WorkspaceController
    window.workspace.init()
