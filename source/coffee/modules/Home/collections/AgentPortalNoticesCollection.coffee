define [
  'backbone'
  'modules/Home/models/NoticeModel'
], (Backbone, NoticeModel) ->

  class AgentPortalNoticesCollection extends Backbone.Collection

    model : NoticeModel

    sync : (method, collection, options) ->
      options.headers =
        'Authorization' : "Basic #{@digest}"
      Backbone.sync method, collection, options
