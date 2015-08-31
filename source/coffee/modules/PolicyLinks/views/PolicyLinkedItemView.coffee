define [
  'BaseView'
  'modules/PolicyLinks/models/PolicyLinkModel'
], (BaseView, PolicyLinkModel) ->

  class PolicyLinksView extends BaseView

    receivedTemplate : """
    <p>
      {{relationship}} Policy #:
      <a href="\#{{controller.baseRoute}}/policy/{{quoteNumber}}/{{insuredLastName}}%20{{policyId}}">
        {{policyId}} <span class="glyphicon glyphicon-new-window"></span>
      </a>
    </p>
    <p><em>Effective {{effectiveDate}}</em></p>
    """

    retrievingTemplate : """
    <p>Retrieving Linked Policy Data&hellip; <img src="/img/wpspin_light.gif" height="16" width="16"></p>
    """

    errorTemplate : """
    <p class="alert alert-danger pc-alert" role="alert"><strong>{{{status}}}</strong>: {{{statusText}}}</p>
    """

    initialize : (options) ->
      _.bindAll this, 'renderRetrieving', 'renderRetrieved', 'renderError'
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
