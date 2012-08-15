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
    cookie     : 'lib/jquery.cookie'
    xml2json   : 'lib/jquery.xml2json'
    text       : 'lib/text'
    domReady   : 'lib/domReady'
    json       : 'lib/json2'
    loader     : 'lib/heartcode-canvasloader'
  priority: ['jquery']
  shim:
      'json' : 
        deps    : ['jquery']
        exports : 'JSON'
      'cookie' : ['jquery']
      'amplify' :
        deps    : ['jquery', 'json']
        exports : 'amplify'
      'loader' :
        deps    : ['jquery']
        exports : 'CanvasLoader'
      'xml2json' : ['jquery']

require [
  "jquery",
  "underscore",
  "WorkspaceController",
  "amplify",
  "loader",
  "domReady!"
], ($, _, WorkspaceController, amplify, CanvasLoader, doc) ->
  $ ->
    WorkspaceController.init()