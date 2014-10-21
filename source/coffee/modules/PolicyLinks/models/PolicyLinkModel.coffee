define [
  'backbone'
  'moment'
], (Backbone, moment) ->

  class PolicyLinkModel extends Backbone.Model

    dateFormat : 'MMM DD, YYYY'

    url : ->
      "#{@options.urlRoot}?q=#{@searchId}"

    parse : (resp) ->
      unless resp.policies.length is 0
        policy = resp.policies[0]
        effectiveDate = moment policy.effectiveDate
        resp.effectiveDate   = effectiveDate.format @dateFormat
        resp.quoteNumber     = policy.identifiers.quoteNumber
        resp.insuredLastName = policy.insured.lastName
      resp

    initialize : (options) ->
      _.bindAll this, 'syncRequest'
      id = options.policyId

      # Search the linked policy ID minus the 2-digit term
      @searchId = id.substring 0, id.length - 2
      @options = options

    requestData : ->
      request = @fetch
        headers  :
          'Accept'        : 'application/json'
          'Authorization' : "Basic #{@options.auth}"
      request.done @syncRequest
      @trigger 'request', this

    syncRequest : (data, status, xhr) ->
      if data.policies.length is 0
        err =
          status     : 'Empty Result'
          statusText : "Policy #{@options.policyId} Not Found"
        @trigger 'error', this, err
      else
        @trigger 'sync', this, xhr

