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
      @el         = options.view.el
      @$el        = options.view.$el
      @controller = options.view.options.controller

      # Attach function to window to catch ready() calls
      # from PolicySummary SWF
      window.policyViewInitSWF = =>
        @initialize_swf()

    render : (options) ->
      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      
      if !options?
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
      @policy_summary   = @$el.find("#policy-summary-#{@cid}")

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)
      console.log 'render'
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
    resize_element : (el, offset) ->
      offset = offset || 0
      el_height = Math.floor((($(window).height() - (220 + offset))/$(window).height())*100) + "%"
      el.css(
        'min-height' : el_height
        'height'     : $(window).height() - (220 + offset)
        )

    # Load Flex Policy Summary
    show_overview : ->
      @policy_header.hide()
      @iframe.hide()
      @resize_element @policy_summary

      # If this el is missing then create it
      if @$el.find("#policy-summary-#{@cid}").length is 0
        @$el.find("#policy-header-#{@cid}").after(@policy_summary)

      if @$el.find("#policy-summary-#{@cid}").length > 0
        @policy_summary.show()
        #swfobject.embedSWF(swfUrlStr, replaceElemIdStr, widthStr, heightStr, swfVersionStr, xiSwfUrlStr, flashvarsObj, parObj, attObj, callbackFn)
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
            }
        )

    # When the SWF calls ready() this is fired and passed
    # policy data along
    initialize_swf : ->
      if @options.module.app?
        context = @options.module.app.context

      context.parent_app ?= @options.module.app.app

      doc = @controller.config.get('document')
      config = doc.find("ConfigItem[name=#{context.parent_app}] ConfigItem[name=businesses] ConfigItem[name=#{context.businesses.name}] ConfigItem[name=production]")
      serializer = new XMLSerializer()

      obj      = swfobject.getObjectById("policy-summary-#{@cid}");
      digest   = Base64.decode(@model.get('digest')).split ':'
      settings =
        "parentAuthtoken" : "Y29tLmljczM2MC5hcHBzLmluc2lnaHRjZW50cmFsOjg4NTllY2IzNmU1ZWIyY2VkZTkzZTlmYTc1YzYxZDRl",
        "policyId"        : @model.id

      console.log digest
      console.log settings
      console.log serializer.serializeToString(config[0])

      if digest[0]? and digest[1]?
        obj.init(digest[0], digest[1], serializer.serializeToString(config[0]), settings)

    # Load mxAdmin into workarea and inject policy header
    show_ipmchanges : ->
      header = @Mustache.render tpl_ipm_header, @model.get_ipm_header()
      @policy_header.html(header)
      @policy_header.show()

      @policy_summary.hide()
      swfobject.removeSWF("policy-summary-#{@cid}")

      @iframe.show()
      @iframe.attr('src', '/mxadmin/index.html')
      @resize_element(@iframe, @policy_header.height())

  PolicyView