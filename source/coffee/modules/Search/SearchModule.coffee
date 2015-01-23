define [
  'modules/Search/SearchView'
], (SearchView) ->

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
      _.extend @, Backbone.Events
     
    # Any bootstrapping should happen here. When done remove the loader image.
    # view.remove_loader will callback Module.render()
    #
    load: ->
      setTimeout (=> @view.remove_loader true), 200
        
    # Do whatever rendering animation needs to happen here
    render : ->
      @search_view = new SearchView
        el         : @view.$el
        controller : @view.controller
        module     : @
