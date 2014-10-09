define [
  'BaseCollection',
  'modules/ReferralQueue/ReferralTaskModel'
], (BaseCollection, ReferralTaskModel) ->

  # Referral Tasks
  # ====
  #
  ReferralTaskCollection = BaseCollection.extend

    model : ReferralTaskModel

    pageDefault : 1

    perPageDefault : 50

    statusDefault : 'New,Pending'

    sortProp : 'lastUpdated'

    sortDir : 'asc'

    sortCache :
      'relatedQuoteId'  : 'asc'
      'insuredLastName' : 'asc'
      'status'          : 'asc'
      'prettySubtype'   : 'asc'
      'lastUpdated'     : 'asc'
      'SubmittedBy'     : 'asc'
      'assignedTo'      : 'asc'

    comparator : (a, b) ->
      dir = if @sortDir is 'asc' then 1 else -1
      propA = @safeLowerCase a.get(@sortProp)
      propB = @safeLowerCase b.get(@sortProp)
      if propA < propB
        return dir
      if propA > propB
        return -dir
      0

    safeLowerCase : (val) ->
      if _.isString val
        val = val.toLowerCase()
      val

    initialize : ->
      @page    = @pageDefault
      @perPage = @perPageDefault
      @status  = @statusDefault

    # **Parse response**  
    # We need to get the XML from pxCentral into a nice JSON format for our
    # models.
    #
    # @param `response` _XML_ Task XML returned from server  
    # @return _JSON_
    parse : (response) ->
      if response
        json = $.fn.xml2json(response)

        # Grab some pagination metadata from the response
        _.extend(this, {
          criteria   : json.criteria
          perPage    : json.itemsPerPage
          page       : json.page
          totalItems : json.totalItems
        })

        return json.Task
      false

    # **Success callback**  
    # We have the option to pass in a custom success callback to make
    # testing easier. Wrapping fetch() in this method also makes it easy
    # to override the default Backbone.sync with our custome headers.
    #
    # @param `collection` _Object_ ReferralTaskCollection  
    # @param `response` _XML_ Task XML from server 
    #
    success_callback : (collection, response) ->
      # console.log [collection, response] # stub

    # **Error callback**  
    #
    # @param `collection` _Object_ ReferralTaskCollection  
    # @param `response` _XML_ Task XML from server 
    #
    error_callback : (collection, response) ->
      collection.trigger 'error', collection, response

    getParams : ->
      params = { media : 'application/xml' }
      params.OwningUnderwriter = @owner if @owner?
      params.OwningAgent       = @agent if @agent?
      params.status            = @status if @status?
      params.page              = @page
      params.perPage           = @perPage
      params

    # **Get Tasks from Server**  
    # We have the option to pass in a custom success callback to make
    # testing easier. Wrapping fetch() in this method also makes it easy
    # to override the default Backbone.sync with our custome headers.
    #
    # @param `callback` _Function_ function to call on AJAX success  
    #
    getReferrals : (callback) ->
      success_callback = callback || @success_callback
      error_callback   = @error_callback
      params           = @getParams()

      @fetch(
        data        : params
        dataType    : 'xml'
        contentType : 'application/xml'
        headers     :
          'Authorization'   : "Basic #{@digest}"
          'X-Authorization' : "Basic #{@digest}"
        success : (collection, response) ->
          success_callback.apply(this, [collection, response])
        error : (collection, response) ->
          error_callback.apply(this, [collection, response])
      )

    # **Sort columns**  
    sortTasks : (property) ->
      # property to sort by
      @sortProp = property

      # get the current sort direction
      oldDir = @sortCache[property]
      
      # swap the direction for next time
      @sortDir = newDir = if oldDir is 'asc' then 'desc' else 'asc'
      @sortCache[property] = newDir

      # sort the collection
      @sort()

