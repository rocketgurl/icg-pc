define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'amplify',
  'Helpers',
  'ModalHelper'
], ($, _, Backbone, Mustache, amplify, Helpers, ModalHelper) ->

  BaseView = Backbone.View.extend

    extend : (obj, mixin) ->
      for name, method of mixin
        obj[name] = method

    include : (klass, mixin) ->
      @extend klass.prototype, mixin

    # hook into Amplify.js on all views
    Amplify  : amplify
    
    # Profide Mustache to all views
    Mustache : Mustache
    
    # Provide Helpers to all views
    Helpers  : Helpers
    
    Modal    : new ModalHelper()

    # give all views access to the favicon start / stop methods
    favicon  : Helpers.faviconLoader()

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg

    # Add a disposal method for views
    dispose : ->
      if Backbone.View.dispose?
        Backbone.View.dispose
      else
        @undelegateEvents();
        if (@model && @model.off) then @model.off(null, null, this)
        if (@collection && @collection.off) then @collection.off(null, null, this)
        return this
      