require
  baseUrl: 'js'
  paths: 
    jquery        : 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min'
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

require [
  "jquery",
  "WorkspaceController"
], ($, WorkspaceController) ->
  $ ->
    WorkspaceController.init()