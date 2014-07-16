define [
  'backbone'
  'modules/PolicyQuickView/DocumentModel'
], (Backbone, DocumentModel) ->

  # A mixed, sortable, searchable collection of Notes, Messages & Events
  class DocumentsCollection extends Backbone.Collection

    model : DocumentModel

    sort : (options) ->
      unless @initialized
        options = { silent : false }
      super options

    comparator : (modela, modelb) ->
      a = modela.unixTime
      b = modelb.unixTime
      if a > b
        -1
      else if a < b
        1
      else
        0

    initialize : (models, options) ->
      @options = options
      @policyUrl = options.policyUrl

    getGrouped : ->
      _.groupBy @toJSON(), (model) ->
        return model.docGroup

