"use strict";
require
  baseUrl: 'js'
  paths: 
    jquery     : 'lib/jquery-1.7.2.min'
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

require [
  "jquery",
  "underscore",
  "WorkspaceController",
  "amplify",
  "loader",
  "domReady"
], ($, _, WorkspaceController, amplify, CanvasLoader, domReady) ->

  # Ensure we have an XMLSerializing facility available
  # if not window.XMLSerializer
  #   window.XMLSerializer = ->

  #   window.XMLSerializer.prototype.serializeToString = ( XMLObject ) ->
  #     XMLObject.xml || ''

  # Initialize application when dom is ready
  domReady ->
    WorkspaceController.init()
    