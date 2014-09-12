define [
  'BaseView'
  'modules/PolicyLinks/models/PolicyLinkModel'
], (BaseView, PolicyLinkModel) ->

  class PolicyLinksView extends BaseView

    receivedTemplate : """
    <p><em>Effective {{effectiveDate}}</em></p>
    <p>
      <strong>{{relationship}} Policy #:
        <a href="#" class="policy-id-link" data-policy-id="{{{policyId}}}" data-insured-last-name="{{{insuredLastName}}}" data-quote-number="{{{quoteNumber}}}">
          {{policyId}} <span class="glyphicon glyphicon-new-window"></span>
        </a>
      </strong>
    </p>
    """

    retrievingTemplate : """
    <p>Retrieving Linked Policy Data&hellip; <img src="/img/wpspin_light.gif" height="16" width="16"></p>
    """

    errorTemplate : """
    <p class="alert alert-danger" role="alert"><strong>{{{status}}}</strong>: {{{statusText}}}</p>
    """

    events :
      'click .policy-id-link' : 'openPolicy'

    initialize : (options) ->
      _.bindAll this, 'renderRetrieving', 'renderRetrieved', 'renderError'
      @options = options
      @content = @$('.popover-content')
      @$el.show()

      @model = new PolicyLinkModel
        policyId : options.policyId
        auth     : options.policy.get('digest')
        urlRoot  : options.controller.services.pxcentral + 'policies'

      @model.on 'request', @renderRetrieving
      @model.on 'sync',    @renderRetrieved
      @model.on 'error',   @renderError
      @model.requestData()

    # Activate existing PolicyView tab or open a new one
    openPolicy : (e) ->
      e.preventDefault()

      data   = $(e.currentTarget).data()
      params =
        url   : data.quoteNumber
        label : "#{data.insuredLastName} #{data.policyId}"

      @options.controller.launch_module 'policyview', params
      @options.controller.Router.append_module 'policyview', params

    renderRetrieving : ->
      @content.html @retrievingTemplate
      this

    renderRetrieved : (model) ->
      data = _.extend model.toJSON(), @options
      html = @Mustache.render @receivedTemplate, data
      @content.html html
      this

    renderError : (model, jqXHR) ->
      html = @Mustache.render @errorTemplate, jqXHR
      @content.html html
