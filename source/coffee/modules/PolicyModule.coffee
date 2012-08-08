define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'modules/PolicyView',
  'modules/PolicyModel',
  'amplify'
], ($, _, Backbone, Mustache, PolicyView, PolicyModel, amplify) ->

  class PolicyModule

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

      # Kick off application
      @load()
      
    # Any bootstrapping should happen here. When done remove the loader image.
    # view.remove_loader will callback Module.render()
    #
    load: ->
      # We need to either use the policy # or the quote #
      id = @params.id if @params.id? 
      id ?= @params.url if @params.url?

      console.log @view.options.controller.user

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

      @policy_model.fetch({
        headers :
          'X-Authorization' : "Basic #{@view.options.controller.user.get('digest')}"
          'Authorization'   : "Basic #{@view.options.controller.user.get('digest')}"
        success : (model, resp) =>
          model.response_state()
          switch model.get('fetch_state').code
            when "200"
              model.get_pxServerIndex()
              @render()
            else
              amplify.publish('controller', 'warning', "Sorry, that policy could not be retrieved. #{model.get('fetch_state').text}")
        error : (model, resp) =>
          amplify.publish('controller', 'warning', "Sorry, that policy could not be retrieved. #{resp}")
      })

    # Do whatever rendering animation needs to happen here
    render : ->
      @view.remove_loader()
      @policy_view.render()

    # Simple delay fund if we need it.
    callback_delay : (ms, func) ->
      setTimeout func, ms

      
