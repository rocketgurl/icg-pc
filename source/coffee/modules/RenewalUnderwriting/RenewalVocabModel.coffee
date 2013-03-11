define [
  'BaseModel'
], (BaseModel) ->

  class RenewalVocabModel extends BaseModel

    LOCALSTORAGE_KEY    : 'ics_renewal_vocab'
    LOCALSTORAGE_EXPIRE : 21600000 # store for 6 hours

    initialize : ->
      @use_localStorage(@LOCALSTORAGE_KEY, @LOCALSTORAGE_EXPIRE) 

    url : ->
      if @get('url_root') == undefined
        return false
      "#{@get('url_root')}terms/#{@id}"

    # If we already have data in LocalStorage then move along,
    # otherwise hitup the server to load it in
    checkCache : ->
      @fetch(
          success : (model, response, options) ->
            if model.get('data') != undefined
              return true
            else
              model.fetchIxVocab()

          error : (model, xhr, options) ->
            model.fetchIxVocab()
        )

    # Switch back to traditional XML sync/parse and attempt to grab
    # the XML Enums from server
    fetchIxVocab : ->
      @use_xml()
      @fetch(
          success : @xmlSuccess
          error   : @xmlError
        )

    # Pull out just what we need from the parsed XML and dump the rest
    # Then cache in LocalStorage
    xmlSuccess : (model, response, options) ->
      attr =
        data     : model.get('json').Enumerations.Enumeration
        id       : model.get('id')
        url_root : model.get('url_root')
      model.clear()
      model.set(attr)
      model.use_localStorage(model.LOCALSTORAGE_KEY, model.LOCALSTORAGE_EXPIRE)
      model.save()

    xmlError : (model, xhr, options) ->
      console.log xhr