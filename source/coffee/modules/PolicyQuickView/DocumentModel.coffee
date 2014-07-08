define [
  'backbone'
  'moment'
  'Helpers'
], (Backbone, moment, Helpers) ->

  class DocumentModel extends Backbone.Model

    dateFormat : 'MMM DD, YYYY'

    timeFormat : 'hh:mm A'

    # mapping document subtype to group name for collection grouping purposes
    groups :
      'invoice'     : 'Invoicing'
      'endorse'     : 'Endorsement'
      'renewal'     : 'Renewal'
      'nonrenewal'  : 'NonRenewal'
      'newbusiness' : 'NewBusiness'
      'declination' : 'Declination'

    initialize : ->
      @isAttachment = @has 'AttachedBy'
      href = @get('location') || @get('href') || ''

      @dateTime = @getDateTime()
      @unixTime = @dateTime.valueOf()
      @determineDocGroup()
      @setCachedItems()

      @set
        'cid'        : @cid
        'docUpdated' : @getPrettyDate()
        'docUrl'     : "#{@collection.policyUrl}/#{href}"

      @set('label', @get('name')) if @isAttachment

    determineDocGroup : ->
      if @isAttachment
        @set 'docGroup', 'Attachments'
      else
        _.some @groups, (group, key) =>
          re = new RegExp key, 'i'
          if re.test @get('subtype')
            @set 'docGroup', group
            return true
        @set('docGroup', 'General') unless @has 'docGroup'

    # Get an instance of moment for future use
    getDateTime : ->
      dateString = @get('lastUpdated') || @get('AttachedTimeStamp')
      moment dateString

    # The timestamp formatted in a template-friendly way
    getPrettyDate : ->
      date: @dateTime.format @dateFormat
      time: @dateTime.format @timeFormat

    # Move "CachedItems" into the model for easy access
    setCachedItems : ->
      items = Helpers.sanitizeNodeArray @get('CachedItem')
      _.each items, (item) =>
        @set item.name, item.value
