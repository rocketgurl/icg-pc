define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, Mustache, amplify) ->

  class TestModule

    # Modules need to be able to call into the parent
    # WorkspaceCanvasView to manipulate the canvas area
    # in the browser.
    #
    # @param `view` _Object_ WorkspaceCanvasView
    # @param `app` _Object_ Application object
    # @param `params` _Object_ Applications specific params
    #
    constructor : (@view, @app, @params) ->
      # Kick off application
      @load()
      
    # Any bootstrapping should happen here. When done remove the loader image.
    # view.remove_loader will callback Module.render()
    #
    load: ->
      rnd = Math.floor(Math.random() * (4 - 1 + 1)) + 1;
      @callback_delay rnd * 1000, => 
        @view.remove_loader()

    # Do whatever rendering animation needs to happen here
    render : ->
      @view.$el.html( @app.app_label + ' MODULE BE RENDERED!')

    # Simple delay fund if we need it.
    callback_delay : (ms, func) ->
      setTimeout func, ms
