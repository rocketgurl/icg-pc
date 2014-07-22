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

    # Groups the models by the docIndex property
    # Converts to an array to maintain order
    getGrouped : ->
      grouped = _.groupBy @toJSON(), (model) ->
        return model.docIndex
      _.toArray grouped

