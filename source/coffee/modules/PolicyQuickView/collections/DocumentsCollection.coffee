define [
  'backbone'
  'modules/PolicyQuickView/models/DocumentModel'
], (Backbone, DocumentModel) ->

  class DocumentsCollection extends Backbone.Collection

    model : DocumentModel

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

