define [
  'BaseModel',
  'moment'
], (BaseModel, moment) ->

  # Referral Task
  # ====  
  # Referral Tasks for the queue collection
  #
  ReferralTaskModel = BaseModel.extend

    parse : (data) ->
      data                        = @setDataItems data
      data.assignedToUnderwriting = data.AssignedTo is 'Underwriting'
      data.assignedToAgent        = data.AssignedTo is 'Agent'
      data.OwningAgent            = data.OwningAgent or ''
      data.OwningUnderwriter      = data.OwningUnderwriter or ''
      data.prettySubtype          = @setPrettySubtype data.Subtype 
      data.prettyLastUpdated      = @setPrettyLastUpdated data.lastUpdated
      data.Rush                   = @Helpers.strToBool data.Rush
      data

    # Move dataItems directly onto the model
    setDataItems : (data) ->
      dataItems = @Helpers.sanitizeNodeArray data.DataItem
      _.each dataItems, (item) ->
        data[item.name] = item.value
      data

    setPrettySubtype : (subtype) ->
      subtypeMap =
        'inspectionreview'   : 'Inspection Review'
        'prebindreview'      : 'Loss History'
        'quotingeligibility' : 'Quoting Eligibility'
      @Helpers.prettyMap subtype, subtypeMap

    setPrettyLastUpdated : (lastUpdated) ->
      moment.calendar =
        lastDay  : '[Yesterday at] LT'
        sameDay  : '[Today at] LT'
        nextDay  : '[Tomorrow at] LT'
        lastWeek : '[last] dddd [at] LT'
        nextWeek : 'dddd [at] LT'
        sameElse : 'LLL'
      moment(lastUpdated).calendar()

      