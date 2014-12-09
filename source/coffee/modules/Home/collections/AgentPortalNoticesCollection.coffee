define [
  'backbone'
  'modules/Home/models/NoticeModel'
], (Backbone, NoticeModel) ->

  class AgentPortalNoticesCollection extends Backbone.Collection

    fnicFilters : [
      '^[aA][0-9A-Za-z]{6}$' # Allstate
      '^[fF][0-9]{5}[nN]$'   # All IAs(FNIC)
      '^[sS][0-9A-Za-z]{5}$' # State Farm
    ]

    model : NoticeModel

    url : ->
      "#{@baseUrl}programs/P4-CRU/notices"

    sync : (method, collection, options) ->
      options.headers =
        'Authorization' : "Basic #{@digest}"
      Backbone.sync method, collection, options
