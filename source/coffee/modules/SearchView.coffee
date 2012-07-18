define [
  'BaseView',
  'Messenger',
  'modules/SearchPolicyCollection',
  'text!templates/tpl_search_container.html'
], (BaseView, Messenger, SearchPolicyCollection, tpl_search_container) ->

  SearchView = BaseView.extend

    events :
      "submit .filters form" : "search"

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el                 = options.view.el
      @$el                = options.view.$el
      @controller         = options.view.options.controller
      @policies           = new SearchPolicyCollection()
      @policies.url       = @controller.services.pxcentral + 'policies?modified-after=2012-01-01&modified-before=2012-07-01'
      @policies.container = @

    render : () ->
      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_search_container, { cid : @cid }
      @$el.html html

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

    search : (e) ->
      e.preventDefault()
      search_val = @$el.find('input[type=search]').val()

      # Set Basic Auth headers to request and attempt to
      # get some policies
      @policies.fetch(
        headers :
          'X-Authorization' : "Basic #{@controller.user.get('digest')}"
          'Authorization'   : "Basic #{@controller.user.get('digest')}"
        success : (collection, resp) ->
          collection.render()
        error : (collection, resp) =>
          console.log resp
          @Amplify.publish @cid, 'warning', "There was a problem with this request: #{resp.status} - #{resp.statusText}"
      )
