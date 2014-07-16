define [
  'backbone'
  'modules/PolicyQuickView/AttachmentModel'
], (Backbone, AttachmentModel) ->

  class AttachmentsCollection extends Backbone.Collection

    model : AttachmentModel

