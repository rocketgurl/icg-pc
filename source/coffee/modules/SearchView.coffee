define [
  'BaseView',
  'mustache',
  'text!templates/tpl_search_container.html'
], (BaseView, Mustache, tpl_search_container) ->

  SearchView = BaseView.extend

    events :
      "submit .filters form" : "search"

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el = options.view.el
      @$el = options.view.$el

    render : () ->
      @$el.html Mustache.render tpl_search_container, { cid : @cid }

    search : (e) ->
      e.preventDefault()
      search_val = @$el.find('input[type=search]').val()
