define [
  'modules/Quoting/QuotingActionView',
  'text!modules/Quoting/templates/tpl_home_action.html'
], (QuotingActionView, tpl_home_action) ->

  # Build the main list of action views for the default page
  class HomeAction extends QuotingActionView

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
      config = _.clone @MODULE.CONFIG
      config.ACTIONS = @processActions @MODULE.CONFIG.ACTIONS
      html = @MODULE.VIEW.Mustache.render(tpl_home_action, config)
      @$el.html(html)

    # Dovetail policies only have Broker of Record IPM functions
    # available, so filter out anything else
    processActions : (actions) ->
      if @MODULE.POLICY.isDovetail()
        actions = _.reject actions, (obj) ->
          obj.actions = _.reject obj.actions, (action) ->
            action.view != "BrokerOfRecord"
          obj.actions.length == 0
      else
        actions
