define [
  'BaseCollection',
  'modules/ReferralQueue/ReferralTaskModel'
], (BaseCollection, ReferralTaskModel) ->

  # Referral Tasks
  # ====
  #
  ReferralTaskCollection = BaseCollection.extend

    model : ReferralTaskModel

    initialize : ->

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

    # **Get Tasks from Server**  
    # We have the option to pass in a custom success callback to make
    # testing easier. Wrapping fetch() in this method also makes it easy
    # to override the default Backbone.sync with our custome headers.
    #
    # @param `query` _Object_ Query params for server call 
    # @param `callback` _Function_ function to call on AJAX success  
    #
    getReferrals : (query, callback) ->
      success_callback = callback || @success_callback
      error_callback   = @error_callback
      query            = query || {}

      # Make sure we're always set for XML and have some sensible defaults
      query = _.extend({
          media             : 'application/xml'
          OwningUnderwriter : @email
          perPage           : 25
        }, query)

      @fetch(
        data        : query
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
    # Set the comparator on the collection and then force a sort. This will
    # trigger a reset on the collection and re-render it.
    #
    # @param `field` _String_ Column name  
    # @param `direction` _String_ ASC || DESC 
    #
    sortTasks : (field, direction) ->
      @comparator = (a, b) ->
        dir = if direction == 'asc' then 1 else -1
        if a.get(field) < b.get(field) 
          return dir
        if a.get(field) > b.get(field) 
          return -dir
        0
      @sort()