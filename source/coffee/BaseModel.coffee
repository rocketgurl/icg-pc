define [
  'jquery', 
  'underscore',
  'backbone',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, amplify) ->

  BaseModel = Backbone.Model.extend

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg

    initialize : () ->
      @logger @id
      @logger @cid