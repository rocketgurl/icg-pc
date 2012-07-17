define [
  'BaseView',
  'mustache',
  'Messenger',
  'text!templates/tpl_search_container.html'
], (BaseView, Mustache, Messenger, tpl_search_container) ->

  SearchView = BaseView.extend

    events :
      "submit .filters form" : "search"

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el = options.view.el
      @$el = options.view.$el

    render : () ->
      # Setup flash module & search container
      html = Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += Mustache.render tpl_search_container, { cid : @cid }
      @$el.html html

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

    search : (e) ->
      e.preventDefault()
      search_val = @$el.find('input[type=search]').val()
      @Amplify.publish @cid, 'notice', search_val
