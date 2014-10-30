define [
  'BaseModel',
  'moment'
], (BaseModel, moment) ->

  # Referral Task
  # ====  
  # Referral Tasks for the queue collection
  #
  ReferralTaskModel = BaseModel.extend

    initialize : ->
      @setDataItems()
      @setAssignedTo()
      @setPrettySubtype()
      @setPrettyLastUpdated()

    # Move dataItems directly onto the model
    setDataItems : ->
      model = this
      dataItems = @Helpers.sanitizeNodeArray @get('DataItem')
      _.each dataItems, (item) ->
        model.set item.name, item.value

    # Determine who this task is assigned to based on values in XML
    setAssignedTo : ->
      assignedTo = @get 'AssignedTo'
      @set 'assignedTo', switch assignedTo
        when 'Underwriting' then @get('OwningUnderwriter') or ''
        when 'Agent' then @get('OwningAgent') or ''
        else ''

    setPrettySubtype : ->
      subtype = @get 'Subtype'
      subtypeMap =
        'inspectionreview'   : 'Inspection Review'
        'prebindreview'      : 'Loss History'
        'quotingeligibility' : 'Quoting Eligibility'
      @set 'prettySubtype', (subtypeMap[subtype] or subtype or '')

    setPrettyLastUpdated : ->
      moment.calendar =
        lastDay  : '[Yesterday at] LT'
        sameDay  : '[Today at] LT'
        nextDay  : '[Tomorrow at] LT'
        lastWeek : '[last] dddd [at] LT'
        nextWeek : 'dddd [at] LT'
        sameElse : 'LLL'
      @set 'prettyLastUpdated', moment(@get('lastUpdated')).calendar()

      