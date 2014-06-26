define [
  'backbone'
  'moment'
], (Backbone, moment) ->

  # Standardize Notes & Events models somewhat
  # So that we can easily sort in a collection
  class ActivityModel extends Backbone.Model

    tasksReferenced : {}

    dateFormat : 'MMM DD, YYYY'

    timeFormat : 'h:mm A'

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
      date: @dateTime.format @dateFormat
      time: @dateTime.format @timeFormat

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
      hasBody      = splitContent.length > 0

      # Prepend RE: to title if the task has already been referenced
      # Otherwise, save the taskRef id
      if @tasksReferenced[task.id]
        title = "RE: #{title}"
      else
        @tasksReferenced[task.id] = true

      data =
        raw     : "#{title}\n#{rawContent}"
        title   : title
        body    : if hasBody then splitContent else ''
        hasBody : hasBody

    getEventContent : ->
      contentObj     = @getDataItems 'reasonCodeLabel', 'EffectiveDate'
      contentIsEmpty = _.isEmpty contentObj
      title          = @get 'type'

      if contentIsEmpty
        rawContent = title
      else
        splitContent = _.map(contentObj, (val, key) =>
          if key is 'EffectiveDate'
            date = moment(val).format @dateFormat
            "Effective on: #{date}"
          else
            val
          )
        rawContent = "#{title}\n#{splitContent.join('\n')}"

      data =
        raw     : rawContent
        title   : title
        body    : if contentIsEmpty then '' else splitContent
        hasBody : not contentIsEmpty

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

