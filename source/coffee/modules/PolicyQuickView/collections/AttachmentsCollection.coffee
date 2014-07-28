define [
  'backbone'
  'modules/PolicyQuickView/models/AttachmentModel'
], (Backbone, AttachmentModel) ->

  class AttachmentsCollection extends Backbone.Collection

    model : AttachmentModel

