define [
  'jquery', 
  'underscore',
  'backbone',
  'amplify'
], ($, _, Backbone, amplify) ->

  BaseCollection = Backbone.Collection.extend

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg