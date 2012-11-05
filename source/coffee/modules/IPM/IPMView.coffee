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
    
    # Build and render needed HTML elements within the view
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
        <form accept-charset="utf-8" id="ipm-form-#{@cid}">
          <div id=\"ipm-container-#{@cid}\" class=\"ipm-container\"></div>
        </form>
      """)


    # Check if IPMActionView is in cache and send to render, otherwise
    # load it with Require.js
    #
    # **Callback Village** - when we initialize an ActionView we set a "loaded"
    # event listener on it which should pass the view's HTML to @render(). We
    # also trigger a "ready" event on the view letting it know to go ahead and
    # do whatever build out it needs to.
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
          @VIEW_CACHE[action] = new Action(
            MODULE      : @MODULE
            PARENT_VIEW : this
          )
          @VIEW_CACHE[action].on("loaded", @render, this)
          @VIEW_CACHE[action].trigger "ready"
        , (err) =>
            failedId = err.requireModules && err.requireModules[0]
            @Amplify.publish(@cid, 'warning', "We could not load #{failedId}. Sorry.")
            @route 'Home'

      else
        @VIEW_CACHE[action].on("loaded", @render, this)
        @VIEW_CACHE[action].trigger "ready"

      this

    # **Render**  
    # render() expects action to have a render() method which returns
    # HTML ready to go.
    #
    # @param `action` _IPMActionView_ Instantiated ActionView from route()  
    #
    render :
      dlogger \
      (html) ->
        @remove_loader()

        # Drop in HTML with a fadeOut/In transition
        container = @$el.find("#ipm-container-#{@cid}")
        container.fadeOut 'fast', =>
          container.html(html).fadeIn('fast')

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





