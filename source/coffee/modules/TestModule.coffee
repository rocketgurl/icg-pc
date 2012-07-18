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
      <h2>{{label}} Module is rendered</h2>
      <p>Hell open to christians they were having, Jimmy Henry said pettishly, about their damned Irish language. Where was the marshal, he wanted to know, to keep order in the council chamber. And old Barlow the macebearer laid up with asthma, no mace on the table, nothing in order, no quorum even, and Hutchinson, the lord mayor, in Llandudno and little Lorcan Sherlock doing locum tenens for him. Damned Irish language, language of our forefathers.</p>
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
