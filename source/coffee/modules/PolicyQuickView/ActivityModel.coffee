define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  # Standardize Notes & Events models somewhat
  # So that we can easily sort in a collection
  class ActivityModel extends Backbone.Model

    # Set properties directly on the model for easy sortability
    initialize : (options) ->
      @type = @getActivityType()
      @timeStamp = @getTimeStamp()
      @initiator = @getInitiator()

    getTimeStamp : ->
      dateString = @get('timeStamp') || @get('CreatedTimeStamp')
      Date.parse dateString

    getActivityType : ->
      if @has 'CreatedTimeStamp'
        'Note'
      else if @has 'timeStamp'
        'Event'
      else
        'Unknown'

    getInitiator : ->
      if @type is 'Note'
        @get 'CreatedBy'
      else if @type is 'Event'
        @get('Initiator').text
      else
        'Unknown'