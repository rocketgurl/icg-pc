define [
  'modules/IPM/IPMActionView',
  'text!modules/IPM/templates/tpl_home_action.html'
], (IPMActionView, tpl_home_action) ->

  # Build the main list of action views for the default page
  class HomeAction extends IPMActionView

    events :
      "click .ipm-home-action-view a" : "dispatch"

    initialize : ->
      super
      @ACTION_NAME = "Home"

    ready : ->
      @render()

    dispatch : (e) ->
      e.preventDefault();
      view  = $(e.currentTarget).attr('href')
      @MODULE.VIEW.route(view)

    render : ->
      actions = @MODULE.CONFIG.ACTIONS
      html = @MODULE.VIEW.Mustache.render(tpl_home_action, @MODULE.CONFIG)
      @trigger "loaded", html