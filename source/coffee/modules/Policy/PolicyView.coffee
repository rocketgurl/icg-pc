define [
  'BaseView',
  'Messenger',
  'base64',
  'modules/RenewalUnderwriting/RenewalUnderwritingView',
  'swfobject',
  'text!modules/Policy/templates/tpl_policy_container.html',
  'text!modules/Policy/templates/tpl_policy_error.html',
  'text!modules/Policy/templates/tpl_ipm_header.html',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_wrapper.html',
  'modules/IPM/IPMModule',
  'modules/ZenDesk/ZenDeskView',
  'modules/PolicyRepresentation/PolicyRepresentationView'
], (BaseView, Messenger, Base64, RenewalUnderwritingView, swfobject, tpl_policy_container, tpl_policy_error, tpl_ipm_header, tpl_ru_wrapper, IPMModule, ZenDeskView, PolicyRepresentationView) ->

  PolicyView = BaseView.extend

    events :
      "click .policy-nav a"        : "dispatch"
      "click .policy-error button" : "close"

    # We need to brute force the View's container to the
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @view         = options.view
      @el           = options.view.el
      @$el          = options.view.$el
      @controller   = options.view.options.controller
      @services     = @controller.services
      @module       = options.module
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

        # Need to let the footer know that we changed height
        @module.trigger 'workspace.rendered'


      # On deactivate we destroy the SWF completely. We have to do this so we
      # can find window.reload() when you switch back to this tab, otherwise it
      # reloads anyway, but doesn't get any of the data from the server, and
      # is therefore useless
      @on 'deactivate', () ->
        @teardown_overview()

      @on 'loaded', () ->
        @loaded_state = true
        # Our default state is to show the SWF overview
        if @controller.active_view.cid == @options.view.cid
          @trigger 'activate'

      # If a Policy 404s or otherwise dies we need a solid error message
      # for the user.
      @on 'error', (msg) ->
        @loaded_state = true
        @renderError msg
        if @controller.active_view.cid == @options.view.cid
          @trigger 'activate'

    renderError : (msg) ->
      html = @Mustache.render(tpl_policy_error, { cid : @cid, msg : msg })
      @$el.html html

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

      # We hide a few actions if this is a quote
      hide_actions = []
      if @model.isQuote()
        for action in ['ipmchanges', 'renewalunderwriting', 'servicerequests']
          @$el.find(".policy-nav a[href=#{action}]").parent('li').hide()

      # If this is an IPM policies need an IPMModule instantiated
      if window.IPM_CAPABLE
        if @model.isIPM()
          @IPM = new IPMModule(@model, $("#policy-ipm-#{@cid}"), @controller.user)
        else
          @$el.find(".policy-nav a[href=ipmchanges]").parent('li').hide()
      else
        @$el.find(".policy-nav a[href=ipmchanges]").parent('li').hide()

      # Hide Policy representations if user doesn't have VIEW_ADVANCED <Right>
      if @controller.user.canViewAdvanced() == false
        @$el.find(".policy-nav a[href=policyrepresentations]").parent('li').hide()

      # Cache commonly used jQuery elements
      @cache_elements()

      # Get an array of our policy-nav actions
      @actions = @policy_nav_links.map (idx, item) -> return $(this).attr('href')

      @build_policy_header()
      @policy_header.show()

      # Hide the view
      @$el.css(
          'visibility' : 'hidden'
        )

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

      true


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
        @policy_header.html @Mustache.render tpl_ipm_header, @model.getIpmHeader()

      @policy_header.show()
      @POLICY_HEADER_OFFSET = @policy_header.height()

    resize_view : (element, offset, scroll) ->
      offset = offset ? @POLICY_HEADER_OFFSET
      element = element ? @$el.find("#policy-workspace-#{@cid}")
      @Helpers.resize_element(element, offset, scroll)

    resize_workspace : (element, workspace) ->
      workspace = workspace ? @$el.find("#policy-workspace-#{@cid}")
      @Helpers.resize_workspace(element, workspace)

    show_element : ($elem) ->
      $elem.show()
      # Need to let the footer know that we changed height
      @module.trigger 'workspace.rendered'
      $elem

    hide_element : ($elem) ->
      $elem.hide()
      $elem

    # Check to see if policy-module div exists, otherwise insert into DOM
    createViewContainer : (id, classname, content = null) ->
      id = "#{id}-#{@cid}"
      $div = $("##{id}")
      content = if content? then content else "<div id=\"#{id}\" class=\"#{classname}\"></div>"
      if $div.length == 0
        $("#policy-header-#{@cid}").after content
        $div = $("##{id}")
        $div.addClass 'policy-module'
      $div

    # Hide policy-module container by id
    hideViewContainer : (id) ->
      $div = $("##{id}-#{@cid}")
      if $div.length > 0
        @hide_element $div    

    # Load Flex Policy Summary
    show_overview : ->
      @$el.css(
          'visibility' : 'visible'
        )

      # SWFObject deletes the policy-summary container when it removes Flash
      # so we need to check if its there and drop it back in if its not
      if @$el.find("#policy-summary-#{@cid}").length == 0
        @$el.find("#policy-header-#{@cid}").after("""<div id="policy-summary-#{@cid}" class="policy-iframe policy-swf"></div>""")
        @policy_summary = @$el.find("#policy-summary-#{@cid}")

      if @$el.find("#policy-workspace-#{@cid}").length > 0
        @resize_view(@$el.find("#policy-workspace-#{@cid}"), 0)

        # Now attach a resize event to the window to help Flash
        resizer = _.bind(
          ->
            @resize_view(@$el.find("#policy-workspace-#{@cid}"), 0)
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

        flash_obj.css(
            'visibility' : 'visible'
            'height'     : '93%'
          )

      if @flash_loaded is false
        swfobject.embedSWF(
          "../swf/PolicySummary.swf",
          "policy-summary-#{@cid}",
          "100%",
          "93%", # @policy_summary.height(),
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
      ipm_container = @$el.find("#policy-ipm-#{@cid}")
      @show_element ipm_container
      @resize_view ipm_container

    # Hide IPM Changes
    teardown_ipmchanges : ->
      ipm_container = @$el.find("#policy-ipm-#{@cid}")
      @hide_element ipm_container

    # Load Renewal Underwriting Views
    show_renewalunderwriting : ->
      content = @Mustache.render tpl_ru_wrapper, { cid : @cid }
      $ru_el = @createViewContainer('renewal-underwriting', null, content)

      # If container not already loaded, then insert element into DOM
      if @ru_container == null || @ru_container == undefined
        @ru_container = new RenewalUnderwritingView({
            $el         : $ru_el
            policy      : @model
            policy_view : this
          }).render()
      else
        @resize_workspace(@ru_container.$el, null)
        @show_element $ru_el

    teardown_renewalunderwriting : ->
      @hideViewContainer 'renewal-underwriting'

    show_servicerequests : ->
      $zd_el = @createViewContainer('zendesk', 'zd-container')
 
      # If container not already loaded, then insert element into DOM
      if @zd_container == null || @zd_container == undefined
        @zd_container = new ZenDeskView({
            $el         : $zd_el
            policy      : @model
            policy_view : this
          }).fetch()

      @show_element $zd_el

    teardown_servicerequests : ->
      @hideViewContainer 'zendesk'

    show_policyrepresentations : ->
      $pr_el = @createViewContainer('policyrep', 'policyrep-container')
      
      # If container not already loaded, then insert element into DOM      
      if @pr_container == null || @pr_container == undefined
        @pr_container = new PolicyRepresentationView({
            $el         : $pr_el
            policy      : @model
            policy_view : this
          }).render()

    teardown_policyrepresentations : ->
      @hideViewContainer 'policyrep'

  PolicyView