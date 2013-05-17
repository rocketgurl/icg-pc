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

    # Set up our working area but injecting various HTML containers into the 
    # DOM then kick off the default route
    initialize : (options) ->
      # Keep track of our current sub-view
      @view_state   = ''
      @view_cache   = {}
      @action_cache = {}
      
      @flash_html = ''
      @loader     = {}

      @DEBUG  = options.DEBUG?
      @MODULE = options.MODULE || false

      # Setup a Flash Msg. Container
      @flash_html = @Mustache.render(
        $('#tpl-flash-message').html(),
        { cid : @cid }
      )

      # Setup elements
      @$el = @MODULE.CONTAINER
      @buildHtmlElements()
  
      # If we're in a default state then launch home
      if _.isEmpty @view_state
        @route 'Home'
    
    # **Build and render needed HTML elements within the view**
    buildHtmlElements : ->
      # Drop flash message template and add class just for ipm layout
      @$el.html(@flash_html)
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
    # @view_cache stores rendered IPMActionView instances. When route is fired
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
    # @param `callbacks` _Object_ .success & .error callback methods    
    #
    route : (action, callbacks) ->
      # Save our current location
      @view_state = action

      # Display loader image
      @insert_loader()

      # Deal with callbacks. This is mostly to ease testing.
      callbacks        = callbacks ? {}
      callback_success = callbacks.success ? null
      callback_error   = callbacks.error ? null

      # Cache or load. If we have a load error, then throw up a message and
      # re-route back to the home view
      if !_.has(@view_cache, action)
        require ["#{@MODULE.CONFIG.ACTIONS_PATH}#{action}"], (Action) =>
          @view_cache[action] = $("<div id=\"dom-container-#{@cid}-#{action}\" class=\"dom-container\"></div>")

          @action_cache[action] = new Action(
            MODULE      : @MODULE
            PARENT_VIEW : this
          )

          @hideOpenViews()

          @action_cache[action].on("loaded", @render, this)
          @action_cache[action].trigger "ready"

          if callback_success?
            callback_success.call(this, @action_cache[action], action)

        , (err) =>
            failedId = err.requireModules && err.requireModules[0]
            @Amplify.publish(@cid, 'warning', "We could not load #{failedId}. Sorry.", null, 'nomove')
            @route 'Home'

            if callback_error?
              callback_error.call(this, err, action)

      else
        @remove_loader()
        @hideOpenViews =>
          @view_cache[action].fadeIn('fast')

      this

    # **Hide all open ActionViews**  
    # Loop through @view_cache and any view with display:block are hidden. An
    # optional callback can be passed in as well, fired when fade is complete.
    #
    # @param `callback` _Function_  
    #
    hideOpenViews : (callback) ->
      for action, view of @view_cache
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
          action_view.setElement(@view_cache[@view_state]).render()
          container.append(@view_cache[@view_state]).fadeIn('fast')
          
          # call callback if present
          if callback
            func = _.bind callback, action_view # bind context to callback
            func()

        # Register flash message pubsub for this view
        @messenger = new Messenger(this, @cid) 

    # Drop a loader graphic into the view
    insert_loader : (msg) ->
      @$el.find("#ipm-loader-#{@cid}").show()
      try
        # Drop in message is present
        if msg?
          $("#ipm-spinner-#{@cid} span").html(msg)

        @loader = @Helpers.loader("ipm-spinner-#{@cid}", 100, '#ffffff')
        @loader.setDensity(70)
        @loader.setFPS(48)
      catch e
        @$el.find("#ipm-loader-#{@cid}").hide()
      this
    
        
    remove_loader : ->
      try
        if @loader? && @loader != undefined
          @loader.kill()
          @loader = null
          @$el.find("#ipm-loader-#{@cid}").hide()
          @$el.find("#ipm-spinner-#{@cid} div").remove()
      catch e
        @$el.find("#ipm-spinner-#{@cid} div").remove()
        console.log [e, @$el.find("#ipm-spinner-#{@cid}").html()]
      this
    

    # Display an error from the action, usually not being able to load a file
    actionError : (jqXHR) =>
      name = @view_state || ""
      error_msg = "Could not load view/model for #{@MODULE.POLICY.get('productName')} #{name} : #{jqXHR.status}"
      @Amplify.publish(@cid, 'warning', "#{error_msg}", null, 'nomove')
      @remove_loader()

    # Display a flash message. This is a convenience method making it
    # easier for IPMActionViews to trigger a message.
    displayMessage : (type, msg, delay) ->
      @Amplify.publish(@cid, type, msg, delay, 'nomove')
      this





