define [
  'backbone'
  'mustache'
  'amplify'
  'Helpers'
  'ModalHelper'
], (Backbone, Mustache, amplify, Helpers, ModalHelper) ->

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

    # Backbone to the future!
    # Stealing a useful method from Backbone 0.9.9 until I can get this library updated
    listenTo : (object, events, callback) ->
      listeners = @_listeners || (@_listeners = {})
      id = object._listenerId || (object._listenerId = _.uniqueId('l'))
      listeners[id] = object
      object.on events, callback || this, this
      this

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg

    # Add a disposal method for views
    dispose : ->
      if Backbone.View.dispose?
        Backbone.View.dispose
      else
        @off()
        @$el.off() if @$el
        @undelegateEvents()
        if (@model && @model.off)
          @model.off()
        if (@collection && @collection.off)
          @collection.off()
        return this
      