define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_policy_container.html',
  'text!templates/tpl_ipm_header.html'
], (BaseView, Messenger, tpl_policy_container, tpl_ipm_header) ->

  PolicyView = BaseView.extend

    events : 
      "click .policy-nav a" : "dispatch"

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el         = options.view.el
      @$el        = options.view.$el
      @controller = options.view.options.controller

    render : ->
      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_policy_container, { auth_digest : @model.get('digest'), policy_id : @model.get('pxServerIndex'), cid : @cid }
      @$el.html html

      # Namespace page elements
      #
      # Since we have multiple instances we use the view cid
      # to keep everyone's ID separate. We store refs to these
      # in vars to keep things in one place keep jQuery traversal
      # to a minimum.
      #
      @iframe_id        = "#policy-iframe-#{@cid}"
      @iframe           = @$el.find(@iframe_id)
      @policy_header    = @$el.find("#policy-header-#{@cid}")
      @policy_nav_links = @$el.find("#policy-nav-#{@cid} a")

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

      @show_overview()

    # Switch nav items on/off
    toggle_nav_state : (el) ->
      @policy_nav_links.removeClass 'select'
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

    # Size the iframe to the approximate view area of the workspace
    resize_iframe : (iframe, offset) ->
      offset = offset || 0
      iframe_height = Math.floor((($(window).height() - (220 + offset))/$(window).height())*100) + "%"
      @iframe.css('min-height', iframe_height)

    # Load Flex Policy Summary
    show_overview : ->
      @iframe.attr('src', 'http://fc06.deviantart.net/fs46/f/2009/169/f/4/Unicorn_Pukes_Rainbow_by_Angel35W.jpg')   
      @resize_iframe @iframe

    # Load mxAdmin into workarea and inject policy header
    show_ipmchanges : ->
      header = @Mustache.render tpl_ipm_header, @model.get_ipm_header()
      @policy_header.html(header)

      @iframe.attr('src', '/mxadmin/index.html')
      @resize_iframe(@iframe, @policy_header.height())

  PolicyView