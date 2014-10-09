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

    # Determine who this task is assigned to based on values in XML
    setAssignedTo : ->
      assignedTo = @get 'AssignedTo'
      @set 'assignedTo', switch assignedTo
        when 'Underwriting' then 'Underwriter'
        when 'Agent' then @getOwningAgent()
        else ''

    # Move dataItems directly model properties
    setDataItems : ->
      model = this
      dataItems = @Helpers.sanitizeNodeArray @get('DataItem')
      _.each dataItems, (item) ->
        model.set item.name, item.value

    getOwningAgent : ->
      @get('OwningAgent') or ''

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

      