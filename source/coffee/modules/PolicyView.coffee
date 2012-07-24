define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_policy_container.html',
], (BaseView, Messenger, tpl_policy_container, tpl_module_loader) ->

  PolicyView = BaseView.extend

    events : 
      "click #policy-nav a" : "dispatch"

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el         = options.view.el
      @$el        = options.view.$el
      @controller = options.view.options.controller

    render : ->
      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_policy_container, { auth_digest : @model.get('digest'), policy_id : @model.get('pxServerIndex') }
      @$el.html html

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

    # Dynamically call methods based on href of #policy-nav elements
    # Because JavaScript is dynamic like that, yo.
    # SAFETY: We namespace the function signature and also make
    # sure it actually exists before attempting to call it.
    dispatch : (e) ->
      e.preventDefault()
      $e = $(e.currentTarget)
      func = @["show_#{$e.attr('href')}"]
      if _.isFunction(func)
        func.apply(this)

    show_overview : ->
      console.log 'overviewing!'
      @Amplify.publish @cid, 'success', 'You be overviewin!'

    # Load mxAdmin into workarea
    show_ipmchanges : ->
      @$el.find('#policy-iframe').attr('src', '/mxadmin/index.html')
      

  PolicyView