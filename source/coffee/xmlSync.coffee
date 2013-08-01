define [
  'jquery',
  'underscore',
  'backbone'
], ($, _, Backbone) ->

  originalSync = Backbone.sync

  XMLSync = (method, model, options) ->

    sync_options =
      dataType        : 'xml'
      contentType     : 'application/xml'
      processData     : false
      withCredentials : true # for CORS

    # If model has Basic Auth then we need to send the header
    if (model.get('digest') != undefined || model.get('digest') != null)
      sync_options.headers =
        'Authorization' : "Basic #{model.get('digest')}"

    options = _.extend(options, sync_options)

    originalSync.apply(Backbone, [ method, model, options ])