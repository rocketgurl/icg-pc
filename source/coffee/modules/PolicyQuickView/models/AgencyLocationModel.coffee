define [
  'backbone'
], (Backbone) ->

  # Grabs the Agency Location as an XML blob from ixDirectory.
  # Parses it to json. Surfaces some useful values for easy access
  class AgencyLocationModel extends Backbone.Model

    url : ->
      "#{@urlRoot}/#{@alc}"

    parse : (resp) ->
      resp = $.fn.xml2json resp
      _.each resp.DataItem, (item) ->
        resp[item.name] = item.value
      resp.PhoneNumber = @formatPhoneNumber resp.PhoneNumber
      resp.MailingAddress = @getAddressByType resp.Addresses.Address, 'mailing'
      resp

    initialize : (options) ->
      _.bindAll this, 'syncRequest'
      @POLICY  = options.policy
      @urlRoot = options.urlRoot
      @alc     = @POLICY.getAgencyLocationCode()
      @fetchXML() if @alc

    fetchXML : ->
      request = @fetch
        dataType : 'xml'
        headers  :
          'Authorization' : "Basic #{@get('auth')}"
      request.done @syncRequest

    syncRequest : (data, status, xhr) ->
      @trigger 'sync', this, xhr

    getAddressByType : (addresses, type) ->
      _.find addresses, (addr) ->
        addr.type is type

    formatPhoneNumber : (phone) ->
      pattern = /(\d{3})(\d{3})(\d{4})/
      replacer = (match, p1, p2, p3) -> "#{p1}-#{p2}-#{p3}"
      phone.replace pattern, replacer
