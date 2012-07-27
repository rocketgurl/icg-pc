require
  baseUrl: 'js'
  paths: 
    jquery     : 'lib/jquery-1.7.2.min'
    underscore : 'lib/underscore-min'
    backbone   : 'lib/backbone-min'
    amplify    : 'lib/amplify'
    mustache   : 'lib/requirejs.mustache',
    base64     : 'lib/base64',
    cookie     : 'lib/jquery.cookie',
    xml2json   : 'lib/jquery.xml2json',
    text       : 'lib/text',
    domReady   : 'lib/domReady'
  priority: ['jquery']
  shim:
      'cookie' : 
        deps: ['jquery']
        exports: 'jQuery.fn.cookie'
      'xml2json' : ['jquery']

require [
  "jquery",
  "cookie",
  "WorkspaceController",
  "domReady!"
], ($, cookie, WorkspaceController, doc) ->
  $ ->
    WorkspaceController.init()