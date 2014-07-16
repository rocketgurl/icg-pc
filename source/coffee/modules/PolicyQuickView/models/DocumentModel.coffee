define [
  'backbone'
  'moment'
  'Helpers'
], (Backbone, moment, Helpers) ->

  class DocumentModel extends Backbone.Model

    dateFormat : 'MMM DD, YYYY'

    timeFormat : 'hh:mm A'

    # mapping document subtype to group name
    # for collection grouping purposes
    # _keys_ are converted to a case insensitve RegExp
    # _values_ are the docGroup into which the model will be bucketed
    groups :
      'application$'          : 'Issuance'
      'quotesheet$'           : 'Issuance'
      'proof$'                : 'Issuance'
      'declarations$'         : 'Issuance'
      'payment$'              : 'Issuance'
      '_letter$'              : 'Issuance'
      '_invoicepackage$'      : 'Issuance'
      'newbusinesspackage'    : 'Issuance'
      'declarationofcoverage' : 'Coverage'
      'invoice'               : 'Invoicing'
      'endorse'               : 'Endorsement'
      'renewal'               : 'Renewal'
      'nonrenewal'            : 'NonRenewal'

    initialize : ->
      @isAttachment = @has 'AttachedBy'
      @dateTime     = @getDateTime()
      @unixTime     = @dateTime.valueOf()

      @set
        'cid'        : @cid
        'docUpdated' : @getPrettyDate()
        'docUrl'     : "#{@collection.policyUrl}/#{@getHref()}"

      # Set the 'docGroup' property
      @determineDocGroup()

      # Normalize attachments to have a label property
      @normaizeAttachmentLabel() if @isAttachment

      # Move "CachedItems" into the model for easy access
      @setCachedItems() if @has 'CachedItem'

    # Rules to determine how to group the documents
    # Sets a 'docGroup' property on the model. The collections sorts and groups.
    # 1. Attachments all go into the Attachments group
    # 2. Declinations all go into the Declinations group
    # 3. Documents timestamped before the Policy Inception all go into the Issuance group
    # 4. All other documents use the @groups mapping
    determineDocGroup : ->
      subtype = @get 'subtype'
      if @isAttachment
        @set 'docGroup', 'Attachments'
      else if /declination/.test subtype
        @set 'docGroup', 'Declination'
      else if @isPriorToPolicyInception()
        @set 'docGroup', 'Issuance'
      else
        _.some @groups, (group, key) =>
          re = new RegExp key, 'i'
          if re.test subtype
            @set 'docGroup', group
            return true
        @set('docGroup', 'General') unless @has 'docGroup'

    # Get an instance of moment for future use
    getDateTime : ->
      dateString = @get('lastUpdated') || @get('AttachedTimeStamp')
      moment dateString

    isPriorToPolicyInception : ->
      inceptionDate = moment @collection.options.policyInceptionDate
      @unixTime < inceptionDate.valueOf()

    # The timestamp formatted in a template-friendly way
    getPrettyDate : ->
      date: @dateTime.format @dateFormat
      time: @dateTime.format @timeFormat

    # Get the location of the document or attachment
    getHref : ->
      @get('location') || @get('href') || ''

    normaizeAttachmentLabel : ->
      name = @get 'name'
      @set 'label', name

    setCachedItems : ->
      items = Helpers.sanitizeNodeArray @get('CachedItem')
      _.each items, (item) =>
        @set item.name, item.value
