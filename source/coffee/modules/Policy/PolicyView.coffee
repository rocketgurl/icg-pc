define [
  'BaseView',
  'Messenger',
  'base64',
  'modules/RenewalUnderwriting/RenewalUnderwritingView',
  'swfobject',
  'text!modules/Policy/templates/tpl_policy_container.html',
  'text!modules/Policy/templates/tpl_ipm_header.html',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_wrapper.html',
  'modules/IPM/IPMModule',
  'modules/ZenDesk/ZenDeskView'
], (BaseView, Messenger, Base64, RenewalUnderwritingView, swfobject, tpl_policy_container, tpl_ipm_header, tpl_ru_wrapper, IPMModule, ZenDeskView) ->

  PolicyView = BaseView.extend

    events : 
      "click .policy-nav a" : "dispatch"

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el           = options.view.el
      @$el          = options.view.$el
      @controller   = options.view.options.controller
      @services     = @controller.services
      @flash_loaded = false

      # We have not been rendered
      @render_state = false

      # PolicyModel has not loaded
      @loaded_state = false

      # Save current route state for this view
      @current_route = null

      # If flash is not loaded, then on an activate event
      # we need to load the flash up. This prevents us
      # from loading always switching to the overview
      # on tab activation
      @on 'activate', () ->
        if @loaded_state
          # This is our first load, so show the SWF
          if @render()
            @show_overview()
            @teardown_ipmchanges()
          # Only show it again if this is the overview route 
          else if @current_route == 'overview' || @current_route == null
            @show_overview()
            @teardown_ipmchanges()


      # On deactivate we destroy the SWF compltely. We have to do this so we
      # can fine window.reload() when you switch back to this tab, otherwise it
      # reloads anyway, but doesn't get any of the data from the server, and
      # is therefore useless
      @on 'deactivate', () ->
        @destroy_overview_swf()

      @on 'loaded', () ->
        @loaded_state = true
        # Our default state is to show the SWF overview
        if @controller.active_view.cid == @options.view.cid
          @trigger 'activate'

    render : (options) ->
      if @render_state == true
        return false

      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      
      if !options?
        html += @Mustache.render tpl_policy_container, { auth_digest : @model.get('digest'), policy_id : @model.get('pxServerIndex'), cid : @cid }
      
      @$el.html html

      # This is to make sure we only render the one time
      # as we have some weird issues where render is call 
      # multiple times (still tracking down.)
      if @render_state == false
        @render_state = true

      # If this is a non-IPM policy then remove IPM changes from nav
      # otherwise go ahead and create an IPMModule
      if @model.isIPM() == false
        @$el.find('.policy-nav a[href=ipmchanges]').parent('li').hide();
      else
        @IPM = new IPMModule(@model, $("#policy-ipm-#{@cid}"), @controller.user)

      # Cache commonly used jQuery elements
      @cache_elements()

      # Get an array of our policy-nav actions
      @actions = @policy_nav_links.map (idx, item) -> return $(this).attr('href')

      # Setup iframe for the Summary SWF
      @build_and_load_swf_iframe()

      # Hide the view
      @$el.hide()

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

      true   


    # Get policy properties (id, user.digest) and setup the iFrame for
    # SWFObject, injecting said properties into object.
    build_and_load_swf_iframe : ->
      # iFrame properties
      # props =
      #   policy_id : @model.get('pxServerIndex')
      #   ipm_auth  : @model.get('digest')
      #   routes    : @controller.services

      # Load iFrame and pass in policy properties
      # @iframe.attr('src', '/mxadmin/index.html')
      # @iframe.bind 'load', =>
      #   @iframe[0].contentWindow.inject_properties(props)
      #   @iframe[0].contentWindow.load_mxAdmin()


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

      @route action, $e

    # **Route**  
    # Call the `action` and teardown all other views
    #
    # @param `action` _String_ action name  
    # @param `el` _HTML Element_    
    # @return _Boolean_  
    #
    route : (action, el) ->
      if !action?
        false
      @current_route = action
      @teardown_actions _.filter(@actions, (item) -> 
        return item != action
      )
      @toggle_nav_state el # turn select state on/off

      func = @["show_#{action}"]
      if _.isFunction(func)
        func.apply(this)

      true


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
        @$el.find("#policy-header-#{@cid}").after("""<div id="policy-summary-#{@cid}" class="policy-iframe policy-swf"></div>""")
        @policy_summary = @$el.find("#policy-summary-#{@cid}")

      if @$el.find("#policy-workspace-#{@cid}").length > 0
        @Helpers.resize_element @$el.find("#policy-workspace-#{@cid}")

        # Now attach a resize event to the window to help Flash
        resizer = _.bind(
          ->
            @Helpers.resize_element(@$el.find("#policy-workspace-#{@cid}"))            
          , this)
        resize = _.debounce(resizer, 300);
        $(window).resize(resize);

        # We need to hook into the correct flash container
        # using SWFObject (hackety hack hack)
        flash_obj = $(swfobject.getObjectById("policy-summary-#{@cid}"))

        # WebKit doesn't seem able to hook into getObjectById so we
        # fall back to jQuery
        if _.isEmpty flash_obj
          flash_obj = $("#policy-summary-#{@cid}")

        flash_obj.css('visibility', 'visible').height('100%')

      if @flash_loaded is false
        swfobject.embedSWF(
          "../swf/PolicySummary.swf",
          "policy-summary-#{@cid}",
          "100%",
          "100%", # @policy_summary.height(),
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
      # @policy_summary.hide()
      $("#policy-summary-#{@cid}").css('visibility', 'hidden').height(0)

    # Remove SWFObject/Flash
    destroy_overview_swf : ->
      swfobject.removeSWF("policy-summary-#{@cid}")
      @flash_loaded = false

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

      ipm_container = @$el.find("#policy-ipm-#{@cid}")
      ipm_container.show()
      @Helpers.resize_element(ipm_container, @policy_header.height())

      # @iframe.show()
      # @iframe.attr('src', '/mxadmin/index.html')
      # @Helpers.resize_element(@iframe, @policy_header.height())

    # Hide IPM Changes
    teardown_ipmchanges : ->
      if @policy_header
        @policy_header.hide()
        @$el.find("#policy-header-#{@cid}").hide()
        # @iframe.hide()
        ipm_container = @$el.find("#policy-ipm-#{@cid}")
        ipm_container.hide()

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

    show_servicerequests : ->
      $zd_el = $("#zendesk-#{@cid}")
      if $zd_el.length == 0
        $("#policy-workspace-#{@cid}").append("<div id=\"zendesk-#{@cid}\" class=\"zd-container\"></div>")
        $zd_el = $("#zendesk-#{@cid}")

      @Helpers.resize_element @$el.find("#policy-workspace-#{@cid}")

      # If container not already loaded, then insert element into DOM
      if @zd_container == null || @zd_container == undefined
        @zd_container = new ZenDeskView({
            $el         : $zd_el
            policy      : @model
            policy_view : this
          }).fetch()
      else
        @zd_container.show()

      # We need a policy_header
      @build_policy_header()

    teardown_servicerequests : ->
      $zd_el = $("#zendesk-#{@cid}")
      if $zd_el.length > 0
        @zd_container.hide()

      if @policy_header
        @policy_header.hide()
        @$el.find("#policy-header-#{@cid}").hide()

  PolicyView