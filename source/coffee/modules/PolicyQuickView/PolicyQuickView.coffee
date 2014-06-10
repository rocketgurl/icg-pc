define [
  'tab'
  'BaseView'
  'modules/PolicyQuickView/ServicingTabView'
  'text!modules/PolicyQuickView/templates/tpl_quickview_container.html'
], (tab, BaseView, ServicingTabView, tpl_qv_container) ->

  # PolicyQuickView
  # ====
  # Build container view for PolicyQuickView subviews
  class PolicyQuickView extends BaseView

    initialize : (options) ->
      @CONTROLLER = options.controller
      @POLICY = options.policy
      @tpl_qv_container = @Mustache.render tpl_qv_container, { cid : @cid }
      return this

    render : ->
      @$el.html @tpl_qv_container
      @cache_elements()

      servicing_tab = new ServicingTabView
        controller : @CONTROLLER
        policy     : @POLICY

      @tab_servicing.append servicing_tab.$el
      return this

    cache_elements : ->
      cid = @cid
      @tab_servicing    = @$("#tab-servicing-#{cid}")
      @tab_underwriting = @$("#tab-underwriting-#{cid}")
      @tab_claims       = @$("#tab-claims-#{cid}")
      return this
