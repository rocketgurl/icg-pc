define [
  'BaseCollection'
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

    # Decode the URI component, because encoded email addresses appear to break the API
    url : ->
      "#{@baseURL}"

    sync : (method, collection, options) ->
      options = _.extend options,
        data        : @getParams()
        cache       : false # force non-cached request for IE
        dataType    : 'xml'
        contentType : 'application/xml'
        headers     :
          'Accept'        : 'application/xml'
          'Authorization' : "Basic #{@digest}"
      @jqXHR = Backbone.sync method, collection, options
      @trigger 'request', this, @jqXHR

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
      @resetDefaults()

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
          totalItems : +json.totalItems
        })

        return json.Task
      false

    getParams : ->
      params =
        page    : @page
        perPage : @perPage
        media   : 'application/xml'
      params.OwningUnderwriter = @owner  if @owner?
      params.OwningAgent       = @agent  if @agent?
      params.status            = @status if @status?
      params

    setParam : (param, value, silent) ->
      value = if value is 'default' then @["#{param}Default"] else value
      unless value is @[param]
        @[param] = value
        @trigger "update update:#{param}" unless silent

    resetDefaults : ->
      _.each ['page', 'status', 'perPage'], (param) =>
        @setParam param, 'default', true

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

