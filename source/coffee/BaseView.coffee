define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, Mustache, amplify) ->

  BaseView = Backbone.View.extend

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg