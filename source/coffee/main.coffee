require
  baseUrl: 'js'
  paths: 
    jquery        : 'lib/jquery-1.7.2.min'
    underscore    : 'lib/underscore-min'
    backbone      : 'lib/backbone-min'
    amplify_core  : 'lib/amplify.core.min'
    amplify_store : 'lib/amplify.store.min',
    mustache      : 'lib/requirejs.mustache',
    base64        : 'lib/base64',
    cookie        : 'lib/jquery.cookie',
    xml2json      : 'lib/jquery.xml2json',
    text          : 'lib/text'
  priority: ['jquery']
  shim:
      'cookie'   : ['jquery'],
      'xml2json' : ['jquery']

require [
  "jquery",
  "WorkspaceController"
], ($, WorkspaceController) ->
  $ ->
    WorkspaceController.init()