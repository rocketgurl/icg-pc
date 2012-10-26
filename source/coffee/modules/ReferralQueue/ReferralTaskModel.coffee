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

    # Determine who this task is assigned to based on values in XML
    getAssignedTo : ->
      switch @.get('AssignedTo')
        when "Underwriting" then "Underwriter"
        when "Agent" then @getOwningAgent()
        else ""

    # Find OwningAgent within DataItem array
    getOwningAgent : ->
      if @get('DataItem')?
        item = _.find(@get('DataItem'), (item) ->
            return _.has(item, 'name') && item.name == 'OwningAgent'
          )
        item.value
      else
        return ''

    # Return an Object with all the needed fields for the table row view
    getViewData : ->
      attributes = _.pick(@attributes,
          'relatedQuoteId',
          'insuredLastName',
          'status',
          'Type',
          'lastUpdated',
          'SubmittedBy'
        )
      moment.calendar =
        lastDay  : '[Yesterday at] LT',
        sameDay  : '[Today at] LT',
        nextDay  : '[Tomorrow at] LT',
        lastWeek : '[last] dddd [at] LT',
        nextWeek : 'dddd [at] LT',
        sameElse : 'LLL'
      attributes.lastUpdated = moment(attributes.lastUpdated).calendar()
      attributes.assignedTo = @getAssignedTo()
      attributes



      