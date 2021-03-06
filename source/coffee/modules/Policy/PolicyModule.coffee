define [
  'backbone'
  'mustache'
  'Helpers'
  'modules/Policy/PolicyView'
  'modules/Policy/PolicyModel'
  'Messenger'
  'loader'
], (Backbone, Mustache, Helpers, PolicyView, PolicyModel, Messenger, CanvasLoader) ->

  class PolicyModule

    Amplify : amplify

    # Modules need to be able to call into the parent
    # WorkspaceCanvasView to manipulate the canvas area
    # in the browser.
    #
    # @param `view` _Object_ WorkspaceCanvasView
    # @param `app` _Object_ Application object
    # @param `params` _Object_ Applications specific params
    #
    constructor : (@view, @app, @params) ->
      # Make sure we have some kind of params
      @params     = @app.params if @app.params?
      @controller = @view.options.controller
      @digest     = @controller.user.get('digest')

      # Bind events
      _.extend @, Backbone.Events

      # Kick off application
      # @load()

    # Any bootstrapping should happen here. When done remove the loader image.
    # view.remove_loader will callback Module.render()
    #
    load: ->
      # We need to either use the policy # or the quote #
      id = @params.id if @params.id?
      id ?= @params.url if @params.url?
      urlRoot = @controller.services.pxcentral

      # path to mock policies. uncomment with care.
      # urlRoot = '/tests/mocks/'
      # id = 'CRU4Q-266134_quote.xml'

      @policy_model = new PolicyModel(
        id      : id
        urlRoot : urlRoot
        digest  : @digest
        module  : this
        )

      @policy_view = new PolicyView(
        view   : @view
        module : this
        model  : @policy_model
        )

      @policy_model.on 'policy_error', @throwLoadError, this

      @messenger = new Messenger(@policy_view, @policy_view.cid)
      window.pol = @policy_model

      # ONLY FETCH THE POLICY IF THERE'S A URLROOT
      if not urlRoot
        @render({ flash_only : true })
        @view.remove_loader()

        message = "Sorry, policy #{@policy_model.id} could not be loaded"
        @policy_view.trigger 'error', message
      else
        @policy_model.fetch({
          headers :
            'Authorization'   : "Basic #{@digest}"
          success : (model, response, options) =>
            # console.log id, @app
            # console.log model.toJSON()
            @policy_view.trigger 'loaded'
          error : (model, xhr, options) =>
            @render({ flash_only : true })
            @view.remove_loader()

            # Generate error message
            if xhr.statusText == "error"
              response = "There was a problem retrieving this policy."
            else
              response = "Sorry, policy #{model.id} could not be loaded - #{xhr.status} : #{xhr.statusText}"

            @policy_view.trigger 'error', response

            # Log a hopefully useful ajax error for TrackJS
            info = ""
            try
              info = """
  Policy Fetch XMLHTTPResponse Error (#{xhr.status}) #{xhr.statusText}
  RequestURL: #{model.url()}
  ResponseHeaders: #{xhr.getAllResponseHeaders()}
              """
              throw new Error "Policy Request Error"
            catch ex
              console.info info
        })

      # When this tab is activated
      @on 'activate', ->
        @policy_view.trigger 'activate'

      # When this tab is activated
      @on 'deactivate', ->
        @policy_view.trigger 'deactivate'

    # If the policy throws some crazy crippled client stuff then set off a
    # big error
    throwLoadError : (model) ->
      xhr = model.get('xhr')

      if xhr?.statusText?
        msg = "Could not retrieve policy - #{xhr.statusText}"
        @policy_view.trigger 'error', msg

      # Log a hopefully useful ajax error for TrackJS
      info = ""
      try
        info = """
Policy Load Error
RequestURL: #{model.url()}
        """
        throw new Error "Policy Request Error"
      catch ex
        console.info info
      return false

    # Do whatever rendering animation needs to happen here
    render : (options) ->
      @view.remove_loader(true)
      if @policy_view.render_state is false
        @policy_view.render(options)

    # Simple delay fund if we need it.
    callback_delay : (ms, func) ->
      setTimeout func, ms

