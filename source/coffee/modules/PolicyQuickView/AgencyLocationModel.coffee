define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  # Grabs the Agency Location as an XML blob from ixDirectory.
  # Parses it to json. Surfaces some useful values for easy access
  #
  # @id      : policy.getAgencyLocationId()
  # @urlRoot : ./ixdirectory/api/rest/v2/organizations/<@id>
  # @auth    : IXVOCAB_AUTH
  class AgencyLocationModel extends Backbone.Model

    url : ->
      "#{@urlRoot}/#{@id}"

    parse : (resp) ->
      resp = $.fn.xml2json resp
      _.each resp.DataItem, (item) ->
        resp[item.name] = item.value
      resp.PhoneNumber = @formatPhoneNumber resp.PhoneNumber
      resp.MailingAddress = @getAddressByType resp.Addresses.Address, 'mailing'
      resp

    initialize : (options) ->
      @urlRoot = options.urlRoot
      @fetch
        dataType : 'xml'
        headers  :
          'Authorization' : "Basic #{options.auth}"

    getAddressByType : (addresses, type) ->
      _.find addresses, (addr) ->
        addr.type is type

    formatPhoneNumber : (phone) ->
      pattern = /(\d{3})(\d{3})(\d{4})/
      replacer = (match, p1, p2, p3) -> "#{p1}-#{p2}-#{p3}"
      phone.replace pattern, replacer
