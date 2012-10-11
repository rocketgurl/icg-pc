define [
  'BaseView',
  'Messenger',
  'base64',
  'modules/RenewalUnderwriting/RenewalUnderwritingView',
  'swfobject',
  'text!modules/Policy/templates/tpl_policy_container.html',
  'text!modules/Policy/templates/tpl_ipm_header.html',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_wrapper.html'
], (BaseView, Messenger, Base64, RenewalUnderwritingView, swfobject, tpl_policy_container, tpl_ipm_header, tpl_ru_wrapper) ->

  PolicyView = BaseView.extend

    events : 
      "click .policy-nav a" : "dispatch"

    # We have not been rendered
    render_state : false

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
          @teardown_ipmchanges()

    render : (options) ->
      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      
      if !options?
        html += @Mustache.render tpl_policy_container, { auth_digest : @model.get('digest'), policy_id : @model.get('pxServerIndex'), cid : @cid }
      
      @$el.html html

      # This is to make sure we only render the one time
      # as we have some weird issues where render is call 
      # multiple times (still tracking down.)
      if @render_state is false
        @render_state = true

      # If this is a non-IPM policy then remove IPM changes from nav
      if @model.isIPM() == false
        @$el.find('.policy-nav a[href=ipmchanges]').parent('li').hide();


      # Cache commonly used jQuery elements
      @cache_elements()

      # Get an array of our policy-nav actions
      @actions = @policy_nav_links.map (idx, item) -> return $(this).attr('href')

      # iFrame properties
      props =
        policy_id : @model.get('pxServerIndex')
        ipm_auth  : @model.get('digest')
        routes    : @controller.services

      # Load iFrame and pass in policy properties
      @iframe.attr('src', '/mxadmin/index.html')
      @iframe.bind 'load', =>
        @iframe[0].contentWindow.inject_properties(props)
        @iframe[0].contentWindow.load_mxAdmin()

      # Hide the view
      @$el.hide()

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)      

      if @controller.active_view.cid == @options.view.cid
        @show_overview()
        @teardown_ipmchanges()

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
      $e     = $(e.currentTarget)
      action = $e.attr('href')

      @teardown_actions _.filter(@actions, (item) -> 
        return item != action
      )

      @toggle_nav_state $e # turn select state on/off

      func = @["show_#{action}"]
      if _.isFunction(func)
        func.apply(this)

    # Take an array of actions (or action) and use it
    # to call it's teardown function (if it exists)
    teardown_actions : (actions) ->
      if actions == undefined || actions == null
        return false

      if !_.isArray(actions)
        actions = [actions]

      for action in actions
        func = @["teardown_#{action}"]
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

    # If the policy_header doesn't exist then build it, otherwise
    # just make visible
    build_policy_header : ->
      if @policy_header.html() == ""
        @policy_header.html @Mustache.render tpl_ipm_header, @model.get_ipm_header()
      
      @policy_header.show()

    # Load Flex Policy Summary
    show_overview : ->
      @$el.show()

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

        # WebKit doesn't seem able to hook into getObjectById so we
        # fall back to jQuery
        if _.isEmpty flash_obj
          flash_obj = $("#policy-summary-#{@cid}")

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



    # Hide flash overview
    teardown_overview : ->
      @policy_summary.hide()
      $("#policy-summary-#{@cid}").hide()

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
      if @flash_loaded is true
        return true

      # We need to get some global workspace information to pass along
      # to our SWF
      # workspace = @controller.workspace_state.get('workspace')
      config    = @controller.config.get_config(@controller.workspace_state)

      if not config?
        @Amplify.publish(@cid, 'warning', "There was a problem with the configuration for this policy. Sorry.")

      obj      = swfobject.getObjectById("policy-summary-#{@cid}");
      digest   = Base64.decode(@model.get('digest')).split ':'
      settings =
        "parentAuthtoken"   : "Y29tLmljczM2MC5hcHBzLmluc2lnaHRjZW50cmFsOjg4NTllY2IzNmU1ZWIyY2VkZTkzZTlmYTc1YzYxZDRl",
        "policyId"          : @model.id,
        "applicationid"     : "ixadmin",
        "organizationid"    : "ics",
        "masterEnvironment" : window.ICS360_ENV

      if digest[0]? and digest[1]?
        obj.init(digest[0], digest[1], config, settings)
      else
        @Amplify.publish(@cid, 'warning', "There was a problem with your credentials for this policy. Sorry.")

      @flash_loaded = true # set state

    # Load mxAdmin into workarea and inject policy header
    show_ipmchanges : ->
      @build_policy_header()
      @policy_header.show()

      @iframe.show()
      @iframe.attr('src', '/mxadmin/index.html')
      @resize_element(@iframe, @policy_header.height())

    # Hide IPM Changes
    teardown_ipmchanges : ->
      if @policy_header
        @policy_header.hide()
        @$el.find("#policy-header-#{@cid}").hide()
        @iframe.hide()

    # Load Renewal Underwriting Views
    show_renewalunderwriting : ->
      $ru_el = $("#renewal-underwriting-#{@cid}")
      if $ru_el.length == 0
        $("#policy-workspace-#{@cid}").append @Mustache.render tpl_ru_wrapper, { cid : @cid }
        $ru_el = $("#renewal-underwriting-#{@cid}")

      # If container not already loaded, then insert element into DOM
      if @ru_container == null || @ru_container == undefined
        @ru_container = new RenewalUnderwritingView({
            $el         : $ru_el
            policy      : @model
            policy_view : this
          }).render()
      else
        @ru_container.show()

      # We need a policy_header
      @build_policy_header()

    teardown_renewalunderwriting : ->
      $ru_el = $("#renewal-underwriting-#{@cid}")
      if $ru_el.length > 0
        @ru_container.hide()

      if @policy_header
        @policy_header.hide()
        @$el.find("#policy-header-#{@cid}").hide()

  PolicyView