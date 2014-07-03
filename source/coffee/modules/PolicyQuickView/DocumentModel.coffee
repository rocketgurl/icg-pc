define [
  'backbone'
  'moment'
], (Backbone, moment) ->

  class DocumentModel extends Backbone.Model

    dateFormat : 'MMM DD, YYYY'

    timeFormat : 'h:mm A'

    # mapping document subtype to group name for collection grouping purposes
    groups :
      'invoice'               : 'general'
      'policyinvoicepackage'  : 'general'
      'declarationofcoverage' : 'general'

    initialize : ->
      @dateTime = @getDateTime()
      @unixTime = @dateTime.valueOf()

      @determineDocGroup()

      @setCachedItems()
      @set
        'cid'        : @cid
        'docUpdated' : @getPrettyDate()
        'docUrl'     : "#{@collection.policyUrl}/#{@get('location')}"

    determineDocGroup : ->
      _.some @groups, (group, key) =>
        re = new RegExp key, 'i'
        if re.test @get('subtype')
          @set 'docGroup', group
          return true
      @set('docGroup', 'default') unless @has 'docGroup'

    # Get an instance of moment for future use
    getDateTime : ->
      dateString = @get 'lastUpdated'
      moment dateString

    # The timestamp formatted in a template-friendly way
    getPrettyDate : ->
      date: @dateTime.format @dateFormat
      time: @dateTime.format @timeFormat

    # Move "CachedItems" into the model for easy access
    setCachedItems : ->
      items = @get 'CachedItem'
      _.each items, (item) =>
        @set item.name, item.value
