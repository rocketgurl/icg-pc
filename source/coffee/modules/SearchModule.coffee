define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'modules/SearchView',
  'loader'
], ($, _, Backbone, Mustache, SearchView, CanvasLoader) ->

  class SearchModule

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
      console.log @app
      @load()
      
    # Any bootstrapping should happen here. When done remove the loader image.
    # view.remove_loader will callback Module.render()
    #
    load: () ->
      @callback_delay 500, =>
        @view.remove_loader(true)

    # Do whatever rendering animation needs to happen here
    render : () ->
      @search_view = new SearchView({view : @view, module : @})
      @search_view.render()

    # Simple delay fund if we need it.
    callback_delay : (ms, func) ->
      setTimeout func, ms