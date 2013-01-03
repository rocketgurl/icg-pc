define [
  'modules/IPM/IPMActionView',
  'text!modules/IPM/templates/tpl_home_action.html'
], (IPMActionView, tpl_home_action) ->

  # Build the main list of action views for the default page
  class HomeAction extends IPMActionView

    initialize : ->
      super
      @ACTION_NAME = "Home"
      @events =
        "click .ipm-home-action-view a" : "dispatch"

    ready : ->
      super
      @trigger "loaded", this

    dispatch : (e) ->
      e.preventDefault();
      view  = $(e.currentTarget).attr('href')
      @MODULE.VIEW.route(view)

    render : ->
      actions = @MODULE.CONFIG.ACTIONS
      html = @MODULE.VIEW.Mustache.render(tpl_home_action, @MODULE.CONFIG)
      @$el.html(html)
      