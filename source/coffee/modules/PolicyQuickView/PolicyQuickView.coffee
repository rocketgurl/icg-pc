define [
  'tab'
  'BaseView'
  'text!modules/PolicyQuickView/templates/tpl_quickview_container.html'
], (tab, BaseView, template) ->

  # PolicyQuickView
  # ====
  # Build container view for PolicyQuickView subviews
  class PolicyQuickView extends BaseView

    events : {}

    initialize : (options) ->
      @CONTROLLER = options.controller
      @POLICY = options.policy
      @template = @Mustache.render template, { cid : @cid }

    render : ->
      @$el.html @template
