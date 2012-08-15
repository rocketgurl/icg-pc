define [
  'jquery', 
  'underscore',
  'backbone'
], ($, _, Backbone) ->

  BaseCollection = Backbone.Collection.extend

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg