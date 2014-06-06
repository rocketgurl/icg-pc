define [
  'tab'
  'BaseView'
  'text!modules/PolicyQuickView/templates/tpl_quickview_container.html'
  'text!modules/PolicyQuickView/templates/tpl_servicing_tab.html'
], (tab, BaseView, tpl_qv_container, tpl_servicing_tab) ->

  # PolicyQuickView
  # ====
  # Build container view for PolicyQuickView subviews
  class PolicyQuickView extends BaseView

    initialize : (options) ->
      @CONTROLLER = options.controller
      @POLICY = options.policy

      @tpl_qv_container = @Mustache.render tpl_qv_container, { cid : @cid }
      @tpl_servicing_tab = @Mustache.render tpl_servicing_tab, { cid : @cid }

    render : ->
      @$el.html @tpl_qv_container
      @cache_elements()

      @tab_servicing.html @tpl_servicing_tab

    cache_elements : ->
      cid = @cid
      @tab_servicing    = @$("#tab-servicing-#{cid}")
      @tab_underwriting = @$("#tab-underwriting-#{cid}")
      @tab_claims       = @$("#tab-claims-#{cid}")
