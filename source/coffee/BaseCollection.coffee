define [
  'jquery', 
  'underscore',
  'backbone',
  'amplify',
  'json'
], ($, _, Backbone, amplify, JSON) ->

  BaseCollection = Backbone.Collection.extend

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg