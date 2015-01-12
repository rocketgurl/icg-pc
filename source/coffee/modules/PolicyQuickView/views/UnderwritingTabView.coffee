define [
  'BaseView'
  'text!modules/PolicyQuickView/templates/tpl_underwriting_tab.html'
], (BaseView, tpl_underwriting_tab) ->

  class UnderwritingTabView extends BaseView

    initialize : (options) ->
      @CONTROLLER = options.controller
      @POLICY = options.policy

      @POLICY.on 'change:refresh change:version', @handlePolicyRefresh, this
      @render()

    handlePolicyRefresh : ->
      @render()

    getPolicyStateLabelClass : (policyState) ->
      labelClassMap =
        'Active Quote'        : 'info'
        'Active Policy'       : 'success'
        'Incomplete Quote'    : 'warning'
        'Pending Non-Renewal' : 'warning'
        'Pending Cancellation': 'warning'
        'Cancelled Policy'    : 'danger'
        'Non-Renewed Policy'  : 'danger'
      labelClassMap[policyState] || 'default'

    render : ->
      data = @POLICY.getServicingData() or {}
      data.cid = @cid
      data.PolicyStateLabelClass = @getPolicyStateLabelClass(data.PolicyState)
      @$el.html @Mustache.render tpl_underwriting_tab, data
      return this
