define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_policy_container.html'
], (BaseView, Messenger, tpl_policy_container) ->

  PolicyView = BaseView.extend

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el         = options.view.el
      @$el        = options.view.$el
      @controller = options.view.options.controller

    render : ->
      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_policy_container, { cid : @cid }
      @$el.html html

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)