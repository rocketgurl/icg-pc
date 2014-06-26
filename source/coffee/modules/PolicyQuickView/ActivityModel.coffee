define [
  'backbone'
  'moment'
], (Backbone, moment) ->

  # Standardize Notes & Events models somewhat
  # So that we can easily sort in a collection
  class ActivityModel extends Backbone.Model

    tasksReferenced : {}

    initialize : ->
      
      # put sortable properties directly on the model for easy access
      @dateTime   = @getDateTime()
      @unixOffset = @dateTime.valueOf()
      @type       = @getType()

      # properties used in the template
      @set
        'cid'               : @cid
        'activityType'      : @type
        'activityIsNote'    : @type in ['Note', 'Message']
        'activityInitiator' : @getInitiator()
        'activityDate'      : @getPrettyDate()
        'activityContent'   : @getContent()

    # Determine the type of activity
    getType : ->
      if @has 'TaskRef'
        'Message'
      else if @has 'CreatedTimeStamp'
        'Note'
      else if @has 'timeStamp'
        'Event'
      else
        'Unknown'

    # Get an instance of moment for future use
    getDateTime : ->
      dateString = @get('timeStamp') || @get('CreatedTimeStamp') || ''
      moment dateString

    # The agent responsible for the activity in question
    getInitiator : ->
      if @type is 'Note' or @type is 'Message'
        @get 'CreatedBy'
      else if @type is 'Event'
        @get('Initiator').text || @get('Initiator')
      else
        'Unknown'

    # The timestamp formatted in a template-friendly way
    getPrettyDate : ->
      date: @dateTime.format 'MMM DD, YYYY'
      time: @dateTime.format 'h:mm A'

    # Return the correctly formatted content payload
    # According to the activity type
    getContent : ->
      switch
        when @type is 'Note' then @getNoteContent()
        when @type is 'Event' then @getEventContent()
        when @type is 'Message' then @getMessageContent()
        else {}

    getNoteContent : ->
      rawContent   = @get 'Content'
      splitContent = rawContent.split /\n+/
      hasBody      = splitContent.length > 1

      data =
        raw     : rawContent
        title   : splitContent.shift()
        body    : if hasBody then splitContent else ''
        hasBody : hasBody

    getMessageContent : ->
      rawContent   = @get 'Content'
      splitContent = rawContent.split /\n+/
      task         = @getReferencedTask()
      title        = "#{task.Type} #{task.Subtype}"

      # Prepend RE: to title if the task has already been referenced
      # Otherwise, save the taskRef id
      if @tasksReferenced[task.id]
        title = "RE: #{title}"
      else
        @tasksReferenced[task.id] = true

      data =
        raw     : [title, rawContent].join(' ')
        title   : title
        body    : splitContent
        hasBody : splitContent.length > 0

    # Event content is slightly different than Note & Message content
    # In that it is necessary for the template to know if the
    # Body content is an effective date or reasonCode
    getEventContent : ->
      contentObj = @getDataItems 'reasonCodeLabel', 'EffectiveDate'
      title      = @get 'type'
      isEmpty    = _.isEmpty content

      if isEmpty
        rawContent = title
      else
        rawContent = "#{title} #{_.values(content).join(' ')}"

      data =
        raw     : rawContent
        title   : title
        body    : contentObj
        hasBody : not isEmpty

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

    getReferencedTask : ->
      taskId = @get('TaskRef').idref
      _.find(@collection.tasks, (task) ->
        task.id is taskId
        )

