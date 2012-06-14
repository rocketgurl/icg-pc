// Generated by CoffeeScript 1.3.3
(function() {

  require({
    baseUrl: 'js',
    paths: {
      jquery: 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min',
      underscore: 'lib/underscore-min',
      backbone: 'lib/backbone-min',
      amplify_core: 'lib/amplify.core.min',
      amplify_store: 'lib/amplify.store.min'
    },
    priority: ['jquery']
  });

  require(["lib/text", "app_test"], function(text, app_test) {
    return app_test.init();
  });

}).call(this);
