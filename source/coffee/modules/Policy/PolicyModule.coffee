define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'modules/Policy/PolicyView',
  'modules/Policy/PolicyModel',
  'Messenger',
  'loader'
], ($, _, Backbone, Mustache, PolicyView, PolicyModel, Messenger, CanvasLoader) ->

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
      @params = @app.params if @app.params?

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

      @policy_model = new PolicyModel(
        id      : id
        urlRoot : @view.options.controller.services.pxcentral
        digest  : @view.options.controller.user.get('digest')
        )

      @policy_view = new PolicyView(
        view   : @view
        module : @
        model  : @policy_model
        )

      @policy_model.on 'policy_error', (e) ->
        console.log ['Policy Error', e]

      @messenger = new Messenger(@policy_view, @policy_view.cid)
      digest     = @view.options.controller.user.get('digest')
      window.pol = @policy_model
      @policy_model.fetch({
        headers :
          'Authorization'   : "Basic #{digest}"
          'X-Authorization' : "Basic #{digest}"
        success : (model, resp) =>
          model.response_state()
          switch model.get('fetch_state').code
            when "200"
              model.setModelState()
              model.get_pxServerIndex()
              @policy_view.trigger 'loaded'
            else
              @view.remove_loader()
              @render({ flash_only : true })
              @Amplify.publish(@policy_view.cid, 'warning', "#{model.get('fetch_state').text} - #{$(resp).find('p').text()} - Sorry.")
              @policy_view.trigger 'loaded'
       error : (model, resp) =>
          @render({ flash_only : true })
          @view.remove_loader()

          # Generate error message
          if resp.statusText is "error"
            response = "There was a problem retrieving this policy."
          else
            response = resp.responseText

          @Amplify.publish(@policy_view.cid, 'warning', "#{response} Sorry.")
      })

      # When this tab is activated
      @on 'activate', () ->
        @policy_view.trigger 'activate'

      # When this tab is activated
      @on 'deactivate', () ->
        @policy_view.trigger 'deactivate'

    # Do whatever rendering animation needs to happen here
    render : (options) ->
      @view.remove_loader(true)
      if @policy_view.render_state is false
        @policy_view.render(options)

    # Simple delay fund if we need it.
    callback_delay : (ms, func) ->
      setTimeout func, ms

