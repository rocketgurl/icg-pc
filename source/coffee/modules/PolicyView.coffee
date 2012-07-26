define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_policy_container.html',
  'text!templates/tpl_ipm_header.html'
], (BaseView, Messenger, tpl_policy_container, tpl_ipm_header) ->

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

    # Switch nav items on/off
    toggle_nav_state : (el) ->
      $('#policy-nav a').removeClass 'select'
      el.addClass 'select'

    # Dynamically call methods based on href of #policy-nav elements
    # Because JavaScript is dynamic like that, yo.
    # SAFETY: We namespace the function signature and also make
    # sure it actually exists before attempting to call it.
    dispatch : (e) ->
      e.preventDefault()
      $e = $(e.currentTarget)

      @toggle_nav_state $e # turn select state on/off

      func = @["show_#{$e.attr('href')}"]
      if _.isFunction(func)
        func.apply(this)

    # Load Flex Policy Summary
    show_overview : ->
      console.log 'overviewing!'
      @Amplify.publish @cid, 'success', 'You be overviewin!'

    # Load mxAdmin into workarea and inject policy header
    show_ipmchanges : ->
      header = @Mustache.render tpl_ipm_header, @model.get_ipm_header()
      $('#policy-header').html(header)

      iframe = @$el.find('#policy-iframe')
      iframe.attr('src', '/mxadmin/index.html')     

      # Calc min-height of iFrame in %
      iframe_height = Math.floor((($(window).height() - (220 + $('#policy-header').height()))/$(window).height())*100) + "%"
      console.log iframe_height
      iframe.css('min-height', iframe_height)

  PolicyView