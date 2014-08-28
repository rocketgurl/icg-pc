define [
  'BaseView'
  'modules/PolicyQuickView/views/ProducerView'
  'text!modules/PolicyQuickView/templates/tpl_servicing_tab.html'
], (BaseView, ProducerView, tpl_servicing_tab) ->

  class ServicingTabView extends BaseView

    initialize : (options) ->
      _.bindAll this, 'renderProducerView'

      @CONTROLLER = options.controller
      @POLICY = options.policy

      @POLICY.on 'change:refresh change:version', @handlePolicyRefresh, this
      @render()
      @initProducerView()

    handlePolicyRefresh : ->
      @render()
      @producerView.model.fetchXML()

    initProducerView : ->
      @producerView = new ProducerView
        qvid       : @cid
        controller : @CONTROLLER
        policy     : @POLICY
        el         : @$("#producer-view-#{@cid}")
      @producerView.on 'render', @renderProducerView

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

    getAgentSupportViewUrl : ->
      baseUrl = @CONTROLLER.services.agentSupport
      params =
        policyNumber     : @POLICY.id
        username         : @CONTROLLER.user.get('username')
        agencyLocationId : @POLICY.getAgencyLocationId()

      if baseUrl && _.every params
        "#{baseUrl}?#{$.param(params)}"
      else
        ""

    renderProducerView : (template) ->
      @$("#producer-view-#{@cid}").html template

    render : ->
      servicingData = @POLICY.getServicingData()
      viewData =
        cid                   : @cid
        PolicyStateLabelClass : @getPolicyStateLabelClass(servicingData.PolicyState)
        AgentSupportViewUrl   : @getAgentSupportViewUrl()
      data = _.extend viewData, servicingData
      @$el.html @Mustache.render tpl_servicing_tab, data
      return this
