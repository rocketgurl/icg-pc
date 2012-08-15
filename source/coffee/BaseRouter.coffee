define [
  'jquery', 
  'underscore',
  'backbone'
], ($, _, Backbone) ->

  BaseRouter = Backbone.Router.extend

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg