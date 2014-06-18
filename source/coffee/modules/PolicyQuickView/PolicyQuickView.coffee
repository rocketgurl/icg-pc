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
      @qvContainer = @Mustache.render tpl_qv_container, { cid : @cid }
      return this

    render : ->
      @$el.html @qvContainer
      @cacheElements()

      servicing = new ServicingTabView
        controller : @CONTROLLER
        policy     : @POLICY
        el         : @servicingTabView[0]

      activity = new ActivityView
        policyNotes  : @POLICY.getNotes()
        policyEvents : @POLICY.getEvents()
        el           : @activityView[0]

      return this

    cacheElements : ->
      cid = @cid
      @servicingTabView    = @$("#tab-servicing-#{cid}")
      @underwritingTabView = @$("#tab-underwriting-#{cid}")
      @claimsTabView       = @$("#tab-claims-#{cid}")
      @activityView        = @$("#activity-#{cid}")
      return this
