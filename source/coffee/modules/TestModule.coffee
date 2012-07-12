define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, Mustache, amplify) ->

  class TestModule

    # Modules need to be able to call into the parent
    # WorkspaceCanvasView to manipulate the canvas area
    # in the browser.
    #
    # @param `view` _Object_ WorkspaceCanvasView
    # @param `app` _Object_ Application object
    # @param `params` _Object_ Applications specific params
    #
    constructor : (@view, @app, @params) ->
      # Kick off application
      @load()
      
    # Any bootstrapping should happen here. When done remove the loader image.
    # view.remove_loader will callback Module.render()
    #
    load: ->
      rnd = Math.floor(Math.random() * (4 - 1 + 1)) + 1;
      @callback_delay rnd * 1000, => 
        @view.remove_loader()

    # Do whatever rendering animation needs to happen here
    render : ->
      tpl = """
      <p>{{label}} Module is rendered</p>
      <p><a href="#app" class="open_search_app" data-pc-module="SearchModule" data-pc-policy="123456789">Open another tab</a></p>
      <p><a href="#app" class="open_search_app" data-pc-module="SearchModule" data-pc-policy="987654321">Open another tab</a></p>
      <p><a href="#app" class="open_search_app" data-pc-module="SearchModule" data-pc-policy="987651234">Open another tab</a></p>
      """
      @view.$el.html Mustache.render(tpl, { label : @app.app_label })

      # Attach a handler
      $('.open_search_app').on 'click', (e) =>
        e.preventDefault()
        $e = $(e.target)
        data = $e.data()

        app =
          app       : "policy_view_#{data.pcPolicy}"
          app_label : "Policy view #{data.pcPolicy}"
          params    : data

        @view.launch_child_app app
        

    # Simple delay fund if we need it.
    callback_delay : (ms, func) ->
      setTimeout func, ms
