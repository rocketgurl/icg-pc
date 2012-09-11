define [
  'BaseView',
  'Messenger',
  'base64',
  'text!templates/tpl_policy_container.html',
  'text!templates/tpl_ipm_header.html',
  'swfobject'
], (BaseView, Messenger, Base64, tpl_policy_container, tpl_ipm_header, swfobject) ->

  PolicyView = BaseView.extend

    events : 
      "click .policy-nav a" : "dispatch"

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el           = options.view.el
      @$el          = options.view.$el
      @controller   = options.view.options.controller
      @flash_loaded = false

      # If flash is not loaded, then on an activate event
      # we need to load the flash up. This prevents us
      # from loading always switching to the overview
      # on tab activation
      @on 'activate', () ->
        if @flash_loaded is false
          @show_overview()

    render : (options) ->
      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      
      if !options?
        html += @Mustache.render tpl_policy_container, { auth_digest : @model.get('digest'), policy_id : @model.get('pxServerIndex'), cid : @cid }
      
      @$el.html html

      @cache_elements()

      @$el.hide()

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)      

      if @controller.active_view.cid == @options.view.cid
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

    # Namespace page elements
    #
    # Since we have multiple instances we use the view cid
    # to keep everyone's ID separate. We store refs to these
    # in vars to keep things in one place keep jQuery traversal
    # to a minimum.
    #
    cache_elements : ->
      @iframe_id        = "#policy-iframe-#{@cid}"
      @iframe           = @$el.find(@iframe_id)
      @policy_header    = @$el.find("#policy-header-#{@cid}")
      @policy_nav_links = @$el.find("#policy-nav-#{@cid} a")
      @policy_summary   = @$el.find("#policy-summary-#{@cid}")

    # Size the iframe to the approximate view area of the workspace
    resize_element : (el, offset) ->
      offset = offset || 0
      el_height = Math.floor((($(window).height() - (220 + offset))/$(window).height())*100) + "%"
      el.css(
        'min-height' : el_height
        'height'     : $(window).height() - (220 + offset)
        )

    # Load Flex Policy Summary
    show_overview : ->
      @$el.show()

      if @policy_header
        @policy_header.hide()
        @iframe.hide()

      # SWFObject deletes the policy-summary container when it removes Flash
      # so we need to check if its there and drop it back in if its not
      if @$el.find("#policy-summary-#{@cid}").length is 0
        @$el.find("#policy-header-#{@cid}").after(@policy_summary)
        @policy_summary = @$el.find("#policy-summary-#{@cid}")

      if @policy_summary.length > 0
        @resize_element @policy_summary
        # We need to hook into the correct flash container
        # using SWFObject (hackety hack hack)
        flash_obj = $(swfobject.getObjectById("policy-summary-#{@cid}"))
        flash_obj.show()

      if @flash_loaded is false
        swfobject.embedSWF(
          "../swf/PolicySummary.swf",
          "policy-summary-#{@cid}",
          "100%",
          @policy_summary.height(),
          "9.0.0"
          null,
          null,
          {
            allowScriptAccess : 'always'
          },
          null,
          (e) =>
            @flash_callback(e)
        )

    flash_callback : (e) ->
      if not e.success or e.success is not true
        @Amplify.publish(@cid, 'warning', "We could not launch the Flash player to load the summary. Sorry.")
        return false

      # Grab the SWF ready() function for ourselves!
      window.policyViewInitSWF = =>
        @initialize_swf()

    # When the SWF calls ready() this is fired and passed
    # policy data along
    initialize_swf : ->

      console.log "flash loaded: #{@flash_loaded}"

      if @flash_loaded is true
        return true

      console.log 'initializing flash'

      workspace = @controller.workspace_state.get('workspace')
      config    = @controller.config.get_config(workspace)

      if not config?
        @Amplify.publish(@cid, 'warning', "There was a problem with the configuration for this policy. Sorry.")

      obj      = swfobject.getObjectById("policy-summary-#{@cid}");
      digest   = Base64.decode(@model.get('digest')).split ':'
      settings =
        "parentAuthtoken" : "Y29tLmljczM2MC5hcHBzLmluc2lnaHRjZW50cmFsOjg4NTllY2IzNmU1ZWIyY2VkZTkzZTlmYTc1YzYxZDRl",
        "policyId"        : @model.id

      if digest[0]? and digest[1]?
        obj.init(digest[0], digest[1], config, settings)
      else
        @Amplify.publish(@cid, 'warning', "There was a problem with your credentials for this policy. Sorry.")

      @flash_loaded = true # set state

    # Load mxAdmin into workarea and inject policy header
    show_ipmchanges : ->
      header = @Mustache.render tpl_ipm_header, @model.get_ipm_header()
      @policy_header.html(header)
      @policy_header.show()

      @policy_summary.hide()
      # swfobject.removeSWF("policy-summary-#{@cid}")
      $("#policy-summary-#{@cid}").hide()

      @iframe.show()
      @iframe.attr('src', '/mxadmin/index.html')
      @resize_element(@iframe, @policy_header.height())

  PolicyView