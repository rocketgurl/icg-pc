define [
  'BaseView',
  'Messenger'
], (BaseView, Messenger) ->

  # **Logger decorator**  
  # Do some basic console logging if debugging is switched on
  dlogger = (methodBody) ->
    ->
      if @DEBUG != false && @DEBUG?
        console.log "DEBUG IPMView ->"
        console.log [this, @options, arguments]

      methodBody.apply(this, arguments)

  # IPMView
  # ====  
  # Build container view for IPM functions and do dispatching for
  # actions views. 
  class IPMView extends BaseView

    # Keep track of our current sub-view
    VIEW_STATE : ''
    VIEW_CACHE : {}
    
    FLASH_HTML : ''
    LOADER     : {}

    # Set up our working area but injecting various HTML containers into the 
    # DOM then kick off the default route
    initialize : (options) ->
      @DEBUG  = options.DEBUG?
      @MODULE = options.MODULE || false

      # Setup a Flash Msg. Container
      @FLASH_HTML = @Mustache.render(
        $('#tpl-flash-message').html(),
        { cid : @cid }
      )

      # Setup elements
      @$el = @MODULE.CONTAINER
      @buildHtmlElements()
  
      # If we're in a default state then launch home
      if _.isEmpty @VIEW_STATE
        @route 'Home'
    
    # **Build and render needed HTML elements within the view**
    buildHtmlElements : ->
      # Drop flash message template and add class just for ipm layout
      @$el.html(@FLASH_HTML)
      @$el.find("#flash-message-#{@cid}").addClass('ipm-flash')

      # Drop loader shim into place
      @$el.append("""
        <div id="ipm-loader-#{@cid}" class="ipm-loader">
          <h2 id="ipm-spinner-#{@cid}"><span>Loading action&hellip;</span></h2>
        </div>
      """)

      # Drop container shim into place
      @$el.append("""
          <div id=\"ipm-container-#{@cid}\" class=\"ipm-container\"></div>
      """)


    # **Router**  
    # @VIEW_CACHE stores rendered IPMActionView instances. When route is fired
    # we check the cache to see if it exists, if not we create a new DOM
    # element and then load the IPMActionView with Require.js, then kick off
    # some events on the ActionView that should lead to it getting rendered.
    #
    # If the ActionView already exists in the cache, then we just tell it to
    # show itself (fadeIn) and all the existing ones to switch off.
    #
    # _Callback Village_ - when we initialize an ActionView we set a "loaded"
    # event listener on it which should pass the ActionView itseld to @render(). 
    # We also trigger a "ready" event on the view letting it know to go ahead and
    # do whatever buildup it needs to.
    #
    # @param `action` _String_ name of IPMActionView to loade w/ require()  
    #
    route : (action) ->
      # Save our current location
      @VIEW_STATE = action
      @insert_loader()

      # Cache or load. If we have a load error, then throw up a message and
      # re-route back to the home view
      if !_.has(@VIEW_CACHE, action)
        require ["#{@MODULE.CONFIG.ACTIONS_PATH}#{action}"], (Action) =>

          @VIEW_CACHE[action] = $("<div id=\"dom-container-#{action}\" class=\"dom-container\"></div>")

          ActionView = new Action(
            MODULE      : @MODULE
            PARENT_VIEW : this
          )

          @hideOpenViews()

          ActionView.on("loaded", @render, this)
          ActionView.trigger "ready"

        , (err) =>
            failedId = err.requireModules && err.requireModules[0]
            @Amplify.publish(@cid, 'warning', "We could not load #{failedId}. Sorry.")
            @route 'Home'

      else
        @remove_loader()
        @hideOpenViews =>
          @VIEW_CACHE[action].fadeIn('fast')

      this

    # **Hide all open ActionViews**  
    # Loop through @VIEW_CACHE and any view with display:block are hidden. An
    # optional callback can be passed in as well, fired when fade is complete.
    #
    # @param `callback` _Function_  
    #
    hideOpenViews : (callback) ->
      for action, view of @VIEW_CACHE
        if view.css('display') == 'block'
          view.fadeOut('fast', -> 
              if callback?
                callback()
            )

    # **Render**  
    # Expects an ActionView object (returned from IPMActionView with the
    # loader event). The ActionViews's element is set to the VIEW_CACHE
    # element created earlier, and then ActionView renders(). The VIEW_CACHE
    # element is appended to the IPMView container (@$el) and any callbacks
    # are fired.
    #
    # @param `action_view` _Object_ IPMActionView  
    # @param `callback` _Function_  
    #
    render :
      dlogger \
      (action_view, callback) ->
        @remove_loader()

        # Drop in HTML with a fadeOut/In transition
        container = @$el.find("#ipm-container-#{@cid}")
        container.fadeOut 'fast', =>
          action_view.setElement(@VIEW_CACHE[@VIEW_STATE]).render()
          container.append(@VIEW_CACHE[@VIEW_STATE]).fadeIn('fast')
          
          # call callback if present
          if callback
            callback()

        # Register flash message pubsub for this view
        @messenger = new Messenger(this, @cid) 

    # Drop a loader graphic into the view
    insert_loader : ->
      @$el.find("#ipm-loader-#{@cid}").show()
      try
        @LOADER = @Helpers.loader("ipm-spinner-#{@cid}", 100, '#ffffff')
        @LOADER.setDensity(70)
        @LOADER.setFPS(48)
      catch e
        @$el.find("#ipm-loader-#{@cid}").hide()
    
        
    remove_loader : ->
      try
        if @LOADER? && @LOADER != undefined
          @LOADER.kill()
          @LOADER = null
          @$el.find("#ipm-loader-#{@cid}").hide()
      catch e
        @$el.find("#canvasLoader").remove()
        console.log [e, @$el.find("#ipm-spinner-#{@cid}").html()]
    

    # Display an error from the action, usually not being able to load a file
    actionError : (jqXHR) =>
      name = @VIEW_STATE || ""
      error_msg = "Could not load view/model for #{@MODULE.POLICY.get('productName')} #{name} : #{jqXHR.status}"
      @Amplify.publish(@cid, 'warning', "#{error_msg}")
      @remove_loader()





