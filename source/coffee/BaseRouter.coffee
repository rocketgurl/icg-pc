define [
  'jquery', 
  'underscore',
  'backbone',
  'amplify'
], ($, _, Backbone, amplify) ->

  BaseRouter = Backbone.Router.extend

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg