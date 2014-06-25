define [
  'BaseView'
  'modules/PolicyQuickView/AgencyLocationModel'
  'text!modules/PolicyQuickView/templates/tpl_servicing_tab.html'
], (BaseView, AgencyLocationModel, tpl_servicing_tab) ->

  class ServicingTabView extends BaseView

    initialize : (options) ->
      @QuickView = options.quickview
      @CONTROLLER = options.controller
      @POLICY = options.policy

      @agencyLocationModel = @getAgencyLocationModel()
      @agencyLocationModel.on 'change', @render, this
      return this

    getAgencyLocationModel : ->
      new AgencyLocationModel
        urlRoot : "#{@CONTROLLER.services.ixdirectory}organizations"
        id      : @POLICY.getAgencyLocationCode()
        auth    : @CONTROLLER.IXVOCAB_AUTH

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
      servicingData = @POLICY.getServicingData()
      viewData =
        cid                   : @cid
        Agency                : @agencyLocationModel.toJSON()
        PolicyStateLabelClass : @getPolicyStateLabelClass(servicingData.PolicyState)

      data = _.extend viewData, servicingData
      @$el.html @Mustache.render tpl_servicing_tab, data
      return this
