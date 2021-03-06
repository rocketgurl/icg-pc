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

    # 0. Enrollment - Quote, App, Proof of Insurance, Enrollment Letter, ACH Authorization, Payment Confirmation
    # 1. Policy Packages - Declarations, Renewals and New Business
    # 2. Invoicing - Invoices
    # 3. Endorsements - Endorsements
    # 4. Cancellations - Pending Cancels, Cancels, Restatements, Rescission, and Nonrenewals
    # 5. Attachments - anything attached by a user
    # 6. General - Catchall bucket for any uncaught case
    groups :
      'authorization$' : 'Enrollment'
      'application$'   : 'Enrollment'
      'quotesheet$'    : 'Enrollment'
      'proof$'         : 'Enrollment'
      '_letter$'       : 'Enrollment'
      '_payment$'      : 'Enrollment'
      'newbusiness'    : 'Policy_Packages'
      'reinstate'      : 'Policy_Packages'
      'policyrenew'    : 'Policy_Packages'
      'renewal'        : 'Policy_Packages'
      'declaration'    : 'Policy_Packages'
      'declination'    : 'Policy_Packages'
      'invoice'        : 'Invoicing'
      'endorse'        : 'Endorsements'
      'nonrenew'       : 'Cancellations'
      'cancel'         : 'Cancellations'

    indices :
      'Enrollment'      : 0
      'Policy_Packages' : 1
      'Invoicing'       : 2
      'Endorsements'    : 3
      'Cancellations'   : 4
      'Attachments'     : 5
      'General'         : 6

    initialize : ->
      # Move "CachedItems" into the model for easier access
      @setCachedItems() if @has 'CachedItem'

      @isAttachment = @has 'AttachedBy'
      @dateTime     = @getDateTime()
      @unixTime     = @dateTime.valueOf()

      @set
        'cid'        : @cid
        'docUpdated' : @getPrettyDate()
        'docUrl'     : "#{@collection.policyUrl}/#{@getHref()}"

      # Set the 'docGroup' property
      @determineDocGroup()
      @determineDocIndex()

      # Normalize attachments to have a label property
      @normalizeAttachmentLabel() if @isAttachment

    # Rules to determine how to group the documents
    # Sets a 'docGroup' property on the model. The collection sorts and groups.
    # 1. Attachments all go into the Attachments group
    # 2. All other documents use the @groups mapping
    # 3. Any unmatched docs fall through to the "General" docGroup
    determineDocGroup : ->
      subtype = @get 'subtype'
      if @isAttachment
        @set 'docGroup', 'Attachments'
      else
        _.some @groups, (group, key) =>
          re = new RegExp key, 'i'
          if re.test subtype
            @set 'docGroup', group
            return true
        unless @has 'docGroup'
          @set 'docGroup', 'General'
      this

    # Set an index on the model, so that the group collection is orderable
    determineDocIndex : ->
      group = @get 'docGroup'
      index = if group then @indices[group] else 7
      @set 'docIndex', index
      this

    # Get an instance of moment for future use
    getDateTime : ->
      dateString = @get('lastUpdated') || @get('sourceLastUpdated') || @get('AttachedTimeStamp')
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

    normalizeAttachmentLabel : ->
      name = @get 'name'
      @set 'label', name

    setCachedItems : ->
      items = Helpers.sanitizeNodeArray @get('CachedItem')
      _.each items, (item) =>
        @set item.name, item.value
