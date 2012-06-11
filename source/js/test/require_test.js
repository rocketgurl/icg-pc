require({
  baseUrl: 'js',
  paths: {
    jquery        : 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min',
    underscore    : 'lib/underscore-min',
    backbone      : 'lib/backbone-min',
    amplify_core  : 'lib/amplify.core.min',
    amplify_store : 'lib/amplify.store.min'
  },
  priority: ['jquery']
});

require(["lib/text", "test/app_test"], function(text, app_test) {
  console.log(app_test);
  app_test.init();
});