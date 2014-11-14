define [
  'backbone'
], (Backbone) ->

  class AgentPortalNoticesCollection extends Backbone.Collection

    url : 'https://stage-sagesure-svc.icg360.org/cru-4/agentportal/api/rest/v2/programs/P4-CRU/notices'

    sync : (method, collection, options) ->
      options.dataType = 'json'
      options.headers =
        'Authorization' : "Basic #{@digest}"
      Backbone.sync method, collection, options

    parse : (response) ->
      console.log 'RESPONSE', response
      response

    initialize : ->
      @on 'all', -> console.log arguments

    onError : =>
      console.log 'ONERROR', arguments

