define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'amplify',
  'Helpers'
], ($, _, Backbone, Mustache, amplify, Helpers) ->

  BaseView = Backbone.View.extend

    extend : (obj, mixin) ->
      for name, method of mixin
        obj[name] = method

    include : (klass, mixin) ->
      @extend klass.prototype, mixin

    # hook into Amplify.js on all views
    Amplify : amplify

    # Profide Mustache to all views
    Mustache : Mustache

    # Provide Helpers to all views
    Helpers : Helpers

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg
      