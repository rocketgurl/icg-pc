define [
  'BaseView',
  'Messenger'
], (BaseView, Messenger) ->

  # **Logger decorator**  
  # Do some basic console logging if debugging is switched on
  dlogger = (methodBody) ->
    ->
      if @DEBUG?
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

      # Setup element
      @$el = @MODULE.CONTAINER

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
      @$el.append("<div id=\"ipm-container-#{@cid}\" class=\"ipm-container\"></div>")

      # If we're in a default state then launch home
      if _.isEmpty @VIEW_STATE
        @route 'Home'
    
    # Check if IPMActionView is in cache and send to render, otherwise
    # load it with Require.js
    route : (action) ->

      # Save our current location
      @VIEW_STATE = action

      # Cache or load. If we have a load error, then throw up a message and
      # re-route back to the home view
      if !_.has(@VIEW_CACHE, action)
        @insert_loader()
        require ["#{@MODULE.CONFIG.ACTIONS_PATH}#{action}"], (Action) =>
          @VIEW_CACHE[action] = new Action(MODULE : @MODULE)
          @render(@VIEW_CACHE[action])
        , (err) =>
            failedId = err.requireModules && err.requireModules[0]
            @Amplify.publish(@cid, 'warning', "We could not load #{failedId}. Sorry.")
            @route 'Home'

      else
        @render(@VIEW_CACHE[action])

    # **Render**  
    # render() expects action to have a render() method which returns
    # HTML ready to go.
    render :
      dlogger \
      (action) ->
        @remove_loader()

        # Drop in HTML with a fadeOut/In transition
        container = @$el.find("#ipm-container-#{@cid}")
        container.fadeOut 'fast', =>
          container.html(action.render()).fadeIn('fast')

        # Register flash message pubsub for this view
        @messenger = new Messenger(this, @cid) 

    insert_loader : ->
      @LOADER = @Helpers.loader("ipm-spinner-#{@cid}", 100, '#ffffff')
      @LOADER.setDensity(70)
      @LOADER.setFPS(48)
      @$el.find("#ipm-loader-#{@cid}").show()
        
    remove_loader : ->
      @LOADER.kill()
      @$el.find("#ipm-loader-#{@cid}").hide()





