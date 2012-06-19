// Generated by CoffeeScript 1.3.3
(function() {

  require({
    baseUrl: 'js',
    paths: {
      jquery: 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min',
      underscore: 'lib/underscore-min',
      backbone: 'lib/backbone-min',
      amplify_core: 'lib/amplify.core.min',
      amplify_store: 'lib/amplify.store.min',
      mustache: 'lib/requirejs.mustache',
      base64: 'lib/base64',
      cookie: 'lib/jquery.cookie'
    },
    priority: ['jquery']
  });

  require(["lib/text", "jquery", "WorkspaceController"], function(text, $, WorkspaceController) {
    return $(function() {
      return WorkspaceController.init();
    });
  });

}).call(this);
