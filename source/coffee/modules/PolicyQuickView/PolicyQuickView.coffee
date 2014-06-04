define [
  'BaseView'
  'text!modules/PolicyQuickView/templates/tpl_quickview_container.html'
], (BaseView, template) ->

  # PolicyQuickView
  # ====
  # Build container view for PolicyQuickView subviews
  class PolicyQuickView extends BaseView

    events : {}

    initialize : (options) ->
      @CONTROLLER = options.controller
      @POLICY = options.policy

    render : ->
      template = @Mustache.render template, { cid : @cid }
      @$el.html template
