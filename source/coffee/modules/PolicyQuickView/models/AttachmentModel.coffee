define [
  'backbone'
], (Backbone) ->

  class AttachmentModel extends Backbone.Model

    initialize : ->
      @set 'cid', @cid

