define [
  'backbone'
  'moment'
  'Helpers'
], (Backbone, moment, Helpers) ->

  class NoticeModel extends Backbone.Model

    dateFormat : 'MMM DD, YYYY'

    initialize : ->
      @set
        'dateCreated'   : @formatDateProperty('createdTimestamp')
        'datePublished' : @formatDateProperty('publish')

    formatDateProperty : (prop) ->
      timestamp = @get prop
      moment(timestamp).format @dateFormat

