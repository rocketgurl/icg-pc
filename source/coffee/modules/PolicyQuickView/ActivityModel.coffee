define [
  'backbone'
  'moment'
], (Backbone, moment) ->

  # Standardize Notes & Events models somewhat
  # So that we can easily sort in a collection
  class ActivityModel extends Backbone.Model

    # Set properties directly on the model for easy sortability
    initialize : (options) ->
      
      # put sortable properties directly on the model
      @dateTime   = @getDateTime()
      @unixOffset = @dateTime.valueOf()
      @type       = @getType()

      @set
        'cid'               : @cid
        'activityType'      : @type
        'activityIsNote'    : @type is 'Note'
        'activityInitiator' : @getInitiator()
        'activityDate'      : @getPrettyDate()
        'activityContent'   : @getContent()

    getType : ->
      if @has 'CreatedTimeStamp'
        'Note'
      else if @has 'timeStamp'
        'Event'
      else
        'Unknown'

    getDateTime : ->
      dateString = @get('timeStamp') || @get('CreatedTimeStamp') || ''
      moment dateString

    getInitiator : ->
      if @type is 'Note'
        @get 'CreatedBy'
      else if @type is 'Event'
        @get('Initiator').text || @get('Initiator')
      else
        'Unknown'

    # The timestamp formatted in a template-friendly way
    getPrettyDate : ->
      date: @dateTime.format 'MMM DD, YYYY'
      time: @dateTime.format 'h:mm A'

    # Returns an object mapping given DataItem name to the key
    # And the DataItem value to the value
    getDataItems : (names...) ->
      dataItems = @get 'DataItem'
      results = {}
      _.each(names, (name) ->
        item = _.findWhere dataItems, { 'name' : name }
        results[item.name] = item.value if item
        )
      results 

    getContent : ->
      if @type is 'Note'
        content = @get('Content').split /\n+/
        hasBody = content.length > 1
        data =
          title   : content.shift()
          body    : if hasBody then content else ''
          hasBody : hasBody
      else if @type is 'Event'
        content = @getDataItems 'reasonCodeLabel', 'EffectiveDate'
        data =
          title   : @get('type')
          body    : content

