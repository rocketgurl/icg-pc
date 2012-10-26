define [
  'BaseCollection',
  'modules/ReferralQueue/ReferralTaskModel',
  'xml2json'
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
        json = $.xml2json(response)

        # Grab some pagination metadata from the response
        _.extend(this, {
          criteria     : json.criteria
          itemsPerPage : json.itemsPerPage
          page         : json.page
          totalItems   : json.totalItems
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
    success : (collection, response) ->
      console.log [collection, response] # stub

    # **Get Tasks from Server**  
    # We have the option to pass in a custom success callback to make
    # testing easier. Wrapping fetch() in this method also makes it easy
    # to override the default Backbone.sync with our custome headers.
    #
    # @param `query` _Object_ Query params for server call 
    # @param `callback` _Function_ function to call on AJAX success  
    #
    getReferrals : (query, callback) ->
      callback = callback || @success
      query    = query || {}

      # Make sure we're always set for XML
      query = _.extend({
          media : 'application/xml'
        }, query)

      @fetch(
        data        : query
        dataType    : 'xml'
        contentType : 'application/xml'
        headers     :
          'Authorization'   : "Basic #{@digest}"
          'X-Authorization' : "Basic #{@digest}"
        success : (collection, response) ->
          callback.apply(this, [collection, response])
        error : (collection, response) ->
          console.log [collection, response]
      )
