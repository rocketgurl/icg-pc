define [
  'BaseView'
], (BaseView) ->

  # PolicyQuickView
  # ====
  # Build container view for PolicyQuickView subviews
  class PolicyQuickView extends BaseView

    events : {}

    initialize : (options) ->
      @CONTROLLER = options.controller
      @render()

    render : ->
      console.log @model.toJSON()
