define [
  'popover'
  'BaseView'
  'Messenger'
  'base64'
  'swfobject'
  'modules/PolicyQuickView/PolicyQuickView'
  'modules/IPM/IPMModule'
  'modules/ZenDesk/ZenDeskView'
  'modules/PolicyRepresentation/PolicyRepresentationView'
  'modules/Quoting/QuotingModule'
  'modules/LossHistory/LossHistoryView'
  'modules/RenewalUnderwriting/RenewalUnderwritingView'
  'modules/PolicyLinks/views/PolicyLinksView'
  'text!modules/Policy/templates/tpl_policy_container.html'
  'text!modules/Policy/templates/tpl_policy_error.html'
  'text!modules/Policy/templates/tpl_ipm_header.html'
], (popover, BaseView, Messenger, Base64, swfobject, PolicyQuickView, IPMModule, ZenDeskView, PolicyRepresentationView, QuotingModule, LossHistoryView, RenewalUnderwritingView, PolicyLinksView, tpl_policy_container, tpl_policy_error, tpl_ipm_header) ->
  PolicyView = BaseView.extend

    events :
      "click .policy-nav a"        : "dispatch"
      "click .policy-error button" : "close"
      "click .nav-toggle"          : "toggle_policy_nav"

    # We need to brute force the View's container to the
    # WorkspaceCanvasView's el
    initialize : (options) ->
      _.bindAll this, 'resize_modules', 'resize_swf_container'
      @view          = options.view
      @el            = options.view.el
      @$el           = options.view.$el
      @controller    = options.view.options.controller
      @services      = @controller.services
      @module        = options.module
      @policy_swf_id = "policy-summary-#{@cid}"
      @flash_loaded  = false

      # We have not been rendered
      @render_state = false

      # PolicyModel has not loaded
      @loaded_state = false

      # Save current route state for this view
      @current_route = null

      # Setup overview SWF when view is made visible
      @on 'activate', @onViewActivate

      # On deactivate we destroy the SWF completely. We have to do this so we
      # can find window.reload() when you switch back to this tab, otherwise it
      # reloads anyway, but doesn't get any of the data from the server, and
      # is therefore useless
      # @on 'deactivate', @teardown_overview

      # Sets loaded state and triggers activate
      @on 'loaded', @onViewLoaded

      # If a Policy 404s or otherwise dies we need a solid error message
      # for the user.
      @on 'error', @onViewError

    # If flash is not loaded, then on an activate event
    # we need to load the flash up. This prevents us
    # from loading always switching to the overview
    # on tab activation
    onViewActivate : ->
      if @loaded_state
        @show_element @$el

        # If this is our first load, render the view
        unless @render_state
          @render()

        if @current_route == 'quickview' || !@current_route?
          @show_quickview()

      # Need to let the footer know that we changed height
      @module.trigger 'workspace.rendered'

    # Set loaded state and trigger activate
    onViewLoaded : ->
      @loaded_state = true

      # Our default state is to show the SWF overview
      if @controller.active_view.cid == @options.view.cid
        @trigger 'activate'

    # Throw large error message for user
    onViewError : (msg) ->
      @loaded_state = true
      @renderError msg
      if @controller.active_view.cid == @options.view.cid
        @trigger 'activate'

    renderError : (msg) ->
      html = @Mustache.render(tpl_policy_error, { cid : @cid, msg : msg })
      @$el.html html

    render : ->
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render(tpl_policy_container, {
                auth_digest : @model.get('digest')
                policy_id : @model.get('pxServerIndex')
                cid : @cid
              })
      @$el.html html

      # This is to make sure we only render the one time
      # as we have some weird issues where render is call
      # multiple times (still tracking down.)
      if @render_state == false
        @render_state = true

      # Cache commonly used jQuery elements
      @cache_elements()

      # Control actions visibility
      @adjustActionVisibility()

      # Get an array of our policy-nav actions
      @actions = _.map @policy_nav_links, (link) -> return $(link).attr('href')

      @buildPolicyHeader()

      # Init the policy parent/child links popover
      @initPolicyLinksPopover() if @model.hasLinks()

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

      @embed_swf()

      this

    # Namespace page elements
    #
    # Since we have multiple instances we use the view cid
    # to keep everyone's ID separate. We store refs to these
    # in vars to keep things in one place keep jQuery traversal
    # to a minimum.
    #
    cache_elements : ->
      cid = @cid
      @iframe                 = @$("#policy-iframe-#{cid}")
      @policy_header          = @$("#policy-header-#{cid}")
      @policy_nav_links       = @$("#policy-nav-#{cid} a")
      @policy_workspace       = @$("#policy-workspace-#{cid}")
      @policy_qv_container    = @$("#policy-quickview-#{cid}")
      @policy_swf_container   = @$("#policy-swf-container-#{cid}")
      @policy_summary_swf     = @$("##{@policy_swf_id}")
      @policy_ipm_container   = @$("#policy-ipm-#{cid}")
      @policy_lh_container    = @$("#loss-history-#{cid}")
      @policy_ru_container    = @$("#renewal-underwriting-#{cid}")
      @policy_zd_container    = @$("#zendesk-#{cid}")
      @policy_pr_container    = @$("#policyrep-#{cid}")
      @policy_quote_container = @$("#policy-quoting-#{cid}")
      @policy_modules         = @$(".policy-module")

    # Certain actions are not visible if this is a quote, or a Dovetail policy
    # or the user doesn't have certain permissions
    #
    adjustActionVisibility : ->
      # We hide a few actions if this is a quote
      hide_actions = []
      if @model.isQuote()
        for action in ['renewalunderwriting', 'servicerequests', 'losshistory']
          @$el.find(".policy-nav a[href=#{action}]").parent('li').hide()
      else
        @$el.find(".policy-nav a[href=quoting]").parent('li').hide()

      # If we're not IPM or Dovetail then no IPM for you!
      if @model.isIPM() == false && @model.isDovetail() == false
        @$el.find(".policy-nav a[href=ipmchanges]").parent('li').hide()

      # Hide Policy representations if user doesn't have VIEW_ADVANCED <Right>
      if @controller.user?.canViewAdvanced() == false
        @$el.find(".policy-nav a[href=policyrepresentations]").parent('li').hide()

      # Carrier users are not allowed most things (ICS-2019)
      if @controller.user.isCarrier() == true
        for action in ['renewalunderwriting', 'ipmchanges', 'servicerequests']
          @$el.find(".policy-nav a[href=#{action}]").parent('li').hide()

    initPolicyLinksPopover : ->
      linksPopover = new PolicyLinksView
        controller : @controller
        policy     : @model
        el         : @policy_header.find('.parent-child-popover .popover')

    # Switch nav items on/off
    toggle_nav_state : (el) ->
      @policy_nav_links.removeClass 'select'
      el.addClass 'select'

    open_policy_nav : ->
      @$el.removeClass 'out'

    close_policy_nav : ->
      @$el.addClass 'out'

    toggle_policy_nav : ->
      @$el[if @$el.is('.out') then 'removeClass' else 'addClass'] 'out'

    # Dynamically call methods based on href of #policy-nav elements
    # Because JavaScript is dynamic like that, yo.
    # SAFETY: We namespace the function signature and also make
    # sure it actually exists before attempting to call it.
    dispatch : (e) ->
      e.preventDefault()
      $e     = $(e.currentTarget)
      action = $e.attr('href')
      @route action, $e

    close : (e) ->
      e.preventDefault()
      @view.destroy()
      @controller.reassess_apps()

    # **Route**
    # Call the `action` and teardown all other views
    #
    # @param `action` _String_ action name
    # @param `el` _HTML Element_
    # @return _Boolean_
    #
    route : (action, el) ->
      return false unless action?

      @current_route = action
      @teardown_actions _.filter(@actions, (item) ->
        return item != action
      )
      @toggle_nav_state el # turn select state on/off

      func = @["show_#{action}"]
      if _.isFunction func
        func.apply this

      true


    # Take an array of actions (or action) and use it
    # to call it's teardown function (if it exists)
    teardown_actions : (actions) ->
      return false unless actions?

      actions = [actions] unless _.isArray actions

      for action in actions
        func = @["teardown_#{action}"]
        if _.isFunction func
          func.apply this

    # If the policy_header doesn't exist then build it, otherwise
    # just make visible
    buildPolicyHeader : ->
      ipm_header = @model.getIpmHeader()
      ipm_header.cid = @cid
      @policy_header.html @Mustache.render tpl_ipm_header, ipm_header
      @POLICY_HEADER_OFFSET = @policy_header.height()

    resize_view : (element, offset, scroll) ->
      offset = offset ? @POLICY_HEADER_OFFSET
      @Helpers.resize_element(element, offset, scroll)

    resize_swf_container : ->
      if @policy_swf_container.length
        @resize_view @policy_swf_container

    # Should you ever wish to resize all the policy modules,
    # This is here for you. P.S. don't do this
    resize_modules : ->
      if @policy_modules.length
        _.each @policy_modules, ((module) -> @resize_view @$(module)), this

    show_element : ($elem) ->
      $elem.removeClass 'inactive' if $elem?.length

    hide_element : ($elem) ->
      $elem.addClass 'inactive' if $elem?.length

    # Load Flex Policy Summary
    show_overview : ->
      # SWFObject deletes the policy-summary object when it removes Flash
      # so we need to check if its there and drop it back in if its not
      unless @policy_summary_swf.length
        @policy_summary_swf = @$("""<object id="#{@policy_swf_id}"></object>""")
        @policy_swf_container.append @policy_summary_swf

      unless @flash_loaded
        @embed_swf @policy_swf_id

      @show_element @policy_swf_container

    # Hide flash overview
    teardown_overview : ->
      @hide_element @policy_swf_container

    # Remove SWFObject/Flash
    destroy_overview_swf : ->
      swfobject.removeSWF @policy_swf_id
      @flash_loaded = false

    embed_swf : ->
      @favicon.start()

      opts =
        allowScriptAccess : 'always'
        wmode : 'opaque'

      swfobject.embedSWF(
        @services.pxclient
        @policy_swf_id
        "100%"
        "100%"
        "9.0.0"
        null
        null
        opts
        null
        (e) => @flash_callback(e)
        )

    flash_callback : (e) ->
      if not e.success or e.success is not true
        @Amplify.publish(@cid, 'warning', "We could not launch the Flash player to load the summary. Sorry.")
        @favicon.stop()
        return false

      if e.ref?
        @poll_swf e.ref, @favicon.stop
        
        # Grab SWF ready() function for ourselves
        # See SWF Handler in index.html
        window.policyViewInitSWF = =>
          @initialize_swf e.ref

    # Set up a timer to periodically check value of swfObj.PercentLoaded()
    # Fire the callback when PercentLoaded() == 100
    poll_swf : (obj, callback) ->
      load_check_interval = setInterval(( ->
        if _.isFunction obj.PercentLoaded
          if obj.PercentLoaded() == 100
            clearInterval load_check_interval
            callback()
        else
          clearInterval load_check_interval
      ), 1000)

    # When the SWF calls ready() this is fired and passed
    # policy data along
    initialize_swf : (swf_obj) ->
      return true if @flash_loaded

      # We need to get some global workspace information
      # to pass along to our SWF
      config = @controller.config.get_config @controller.workspace_state

      if not config?
        @Amplify.publish(@cid, 'warning', "There was a problem with the configuration for this policy. Sorry.")

      # swf_obj  = swfobject.getObjectById obj.id
      digest   = Base64.decode(@model.get('digest')).split ':'
      settings =
        "parentAuthtoken"   : "Y29tLmljczM2MC5hcHBzLmluc2lnaHRjZW50cmFsOjg4NTllY2IzNmU1ZWIyY2VkZTkzZTlmYTc1YzYxZDRl",
        "policyId"          : @model.id,
        "applicationid"     : "ixadmin",
        "organizationid"    : "ics",
        "masterEnvironment" : window.ICS360_ENV

      if digest[0]? and digest[1]?
        swf_obj.init digest[0], digest[1], config, settings
      else
        @Amplify.publish(@cid, 'warning', "There was a problem with your credentials for this policy. Sorry.")

      @flash_loaded = true # set state

    show_quickview : ->
      if _.isObject @model.get 'json'
        if @policy_qv_container.html() == ''
          pqv = new PolicyQuickView({
              controller : @controller
              policy     : @model
              el         : @policy_qv_container[0]
            })
          pqv.render()

        @show_element @policy_qv_container

    teardown_quickview : ->
      @hide_element @policy_qv_container

    show_ipmchanges : ->
      if @policy_ipm_container.html() == ''
        ipm = new IPMModule @model, @policy_ipm_container, @controller
      @show_element @policy_ipm_container

    teardown_ipmchanges : ->
      @hide_element @policy_ipm_container

    show_quoting : ->
      if @policy_quote_container.html() == ''
        quoting = new QuotingModule @model, @policy_quote_container, @controller
      @show_element @policy_quote_container

    teardown_quoting : ->
      @hide_element @policy_quote_container
      
    show_renewalunderwriting : ->
      if @policy_ru_container.html() == ''
        ruv = new RenewalUnderwritingView({
            el          : @policy_ru_container[0]
            policy      : @model
            policy_view : this
          })
        ruv.render()

      @show_element @policy_ru_container

    teardown_renewalunderwriting : ->
      @hide_element @policy_ru_container

    show_servicerequests : ->
      if @policy_zd_container.html() == ''
        zdv = new ZenDeskView({
            el          : @policy_zd_container[0]
            policy      : @model
            policy_view : this
          })
        zdv.fetch()

      @show_element @policy_zd_container

    teardown_servicerequests : ->
      @hide_element @policy_zd_container
      
    show_policyrepresentations : ->
      if @policy_pr_container.html() == ''
        prv = new PolicyRepresentationView({
            el          : @policy_pr_container[0]
            policy      : @model
            policy_view : this,
            services    : @services
          })
        prv.render()

      @show_element @policy_pr_container

    teardown_policyrepresentations : ->
      @hide_element @policy_pr_container

    show_losshistory : ->
      if @policy_lh_container.html() == ''
        lhv = new LossHistoryView({
            el          : @policy_lh_container[0]
            policy      : @model
            policy_view : this
          })
        lhv.render()

      @show_element @policy_lh_container

    teardown_losshistory : ->
      @hide_element @policy_lh_container

  PolicyView
