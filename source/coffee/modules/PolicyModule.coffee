define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'modules/PolicyView',
  'modules/PolicyModel',
  'amplify',
  'Messenger'
], ($, _, Backbone, Mustache, PolicyView, PolicyModel, amplify, Messenger) ->

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

      @messenger = new Messenger(@policy_view, @policy_view.cid)

      @policy_model.fetch({
        headers :
          'Authorization'   : "Basic #{@view.options.controller.user.get('digest')}"
          'X-Authorization' : "Basic #{@view.options.controller.user.get('digest')}"
        success : (model, resp) =>
          model.response_state()
          console.log model.get('fetch_state').code
          switch model.get('fetch_state').code
            when "200"
              model.get_pxServerIndex()
              @render()
            else
              @view.remove_loader()
              @render({ flash_only : true })
              amplify.publish(@policy_view.cid, 'warning', "#{model.get('fetch_state').text} - #{$(resp).find('p').text()} Sorry.")
       error : (model, resp) =>
          console.log 'errz!'
          @render({ flash_only : true })
          @view.remove_loader()
          amplify.publish(@policy_view.cid, 'warning', "#{$(resp).find('p').text()} Sorry.")
      })

    # Do whatever rendering animation needs to happen here
    render : (options) ->
      @view.remove_loader(true)
      @policy_view.render(options)

    # Simple delay fund if we need it.
    callback_delay : (ms, func) ->
      setTimeout func, ms

      
