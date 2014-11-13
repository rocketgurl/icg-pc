define [
  'backbone'
], (Backbone) ->

  class AgentPortalNoticesCollection extends Backbone.Collection

    url: 'https://stage-sagesure-svc.icg360.org/cru-4/agentportal/api/rest/v2/programs/P4-CRU/notices'

    initialize : ->
      @on 'all', -> console.log arguments

    fetchNotices : ->
      # console.log "Basic #{@digest}"
      # request = @fetch
      #   headers  :
      #     'Authorization' : "Basic #{@digest}"

      params =
        url         :  @url
        type        : 'GET'
        dataType    : 'json'
        headers     :
          'Authorization' : "Basic #{@digest}"

      xhr = $.ajax params
      xhr.done -> console.log arguments

