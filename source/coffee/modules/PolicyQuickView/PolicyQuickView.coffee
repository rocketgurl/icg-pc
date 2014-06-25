define [
  'tab'
  'BaseView'
  'modules/PolicyQuickView/ServicingTabView'
  'modules/PolicyQuickView/ActivityView'
  'text!modules/PolicyQuickView/templates/tpl_quickview_container.html'
], (tab, BaseView, ServicingTabView, ActivityView, tpl_qv_container) ->

  # PolicyQuickView
  # ====
  # Build container view for PolicyQuickView subviews
  class PolicyQuickView extends BaseView

    initialize : (options) ->
      @CONTROLLER = options.controller
      @POLICY = options.policy
      return this

    render : ->
      @$el.html @Mustache.render tpl_qv_container, { cid : @cid }

      servicing = new ServicingTabView
        controller : @CONTROLLER
        policy     : @POLICY
        el         : document.getElementById("tab-servicing-#{@cid}")

      activity = new ActivityView
        policyNotes  : @POLICY.getNotes()
        policyEvents : @POLICY.getEvents()
        el           : document.getElementById("activity-#{@cid}")

      return this
