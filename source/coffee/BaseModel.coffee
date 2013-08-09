define [
  'jquery', 
  'underscore',
  'backbone',
  'Store',
  'amplify',
  'LocalStorageSync',
  'CrippledClientSync',
  'JSONAuthSync',
  'Helpers',
  'xmlSync'
], ($, _, Backbone, Store, amplify, LocalStorageSync, CrippledClientSync, JSONAuthSync, Helpers, XMLSync) ->

  #### BaseModel
  #
  # All models for PC 2.0 should inherit from BaseModel. This provides sync
  # adapters for localStorage and XML handling, in addition to standard
  # Backbone JSON handling. 
  # 
  class BaseModel extends Backbone.Model

    # make Helpers functions available to all models
    Helpers : Helpers

    # store a ref to Backbone's sync so we can use it again
    backboneSync  : Backbone.sync

    # Traditional Backbone JSON sync + Basic Auth
    backboneAuthSync : JSONAuthSync

    # store a ref to Backbone's parse so we can use it again
    backboneParse : Backbone.Model.prototype.parse

    # Deal with Crippled Clients
    crippledClientSync  : CrippledClientSync

    # Setup XML parsing using CrippledClient
    xmlSync  : XMLSync
    xmlParse : (response, xhr) ->
      if response?
        tree = response
        if _.has(response, 'xml')
          xmlstr = response.xml
        else
          xmlstr = (new XMLSerializer()).serializeToString(response)

      tree = $.parseXML(xmlstr)
      out  = { 'xhr' : xhr }

      if tree?
        out.document   = $(tree)
        out.raw_xml    = xhr.responseText
        out.json       = $.fn.xml2json(out.raw_xml)
      out

    # Response state (Hackety hack hack)
    # 
    # Since we're on **Crippled Client**, all requests come back as
    # 200's and we have to do header parsing to ascertain what 
    # is actually going on. We stash the jqXHR in the model and
    # do some checking to see what the error code really is, then
    # stash that in the model as 'fetch_state'
    #
    response_state : () ->
      xhr = @get 'xhr'
      fetch_state =
        text : xhr.getResponseHeader 'X-True-Statustext'
        code : xhr.getResponseHeader 'X-True-Statuscode'

      # This might be a CORS request in which case we can't
      # get our X-True-Statustext so we need to wing it.
      # This could still cause us some problems down the road.
      if not fetch_state.code?
        if xhr.readyState is 4 and xhr.status is 200
          fetch_state.code = "200"

      @set 'fetch_state', fetch_state
      this

    # Explicitly set sync for this model to Backbone default
    sync : @backboneSync

    # Switch models sync to another adapter
    switch_sync : (sync_adapater) ->
      @sync = @[sync_adapater]

    # Tell model to fetch & parse XML data
    use_xml : () ->
      @sync  = @xmlSync
      @parse = @xmlParse

    # Tell model to fetch & parse XML data from Crippled Clients
    use_cripple : () ->
      @sync  = @crippledClientSync
      @parse = @xmlParse

    # Tell model to use localStorage
    use_localStorage : (storage_key, expire) ->

      options = if expire? then { expires : expire } else null

      # Setup localStorage DB in browswer
      @localStorage = new Store(storage_key, options)
      @localSync    = LocalStorageSync

      @sync  = @localSync
      @parse = @backboneParse

    # Switch back to traditional JSON handling
    use_backbone : () ->
      @sync  = @backboneSync
      @parse = @backboneParse

    # Switch back to traditional JSON handling + Basic Auth
    use_backbone_auth : () ->
      @sync  = @backboneAuthSync
      @parse = @backboneParse

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg

    # Send Flash messages to UI
    flash : (type, msg) ->
      @Amplify.publish 'flash', type, msg

    # Find a property from a collection searching with a String path
    # example: findProperty({foo : { bar : 2 }}, 'foo bar') would return 2,
    # which is equivalent to foo['bar']
    findProperty : (collection, path) ->
      if _.nully(collection) || _.nully(path) then return undefined

      path = if _.isString path then path.split(' ') else path

      # If path is empty, then we're done and return collection
      if _.isArray(path) && path.length == 0 then return collection

      property = _.first(path)

      # If we're looking for an object with a specific attribute, then
      # the property will be in the form: Customer[type=Insured] at which
      # point we break the attribute string into key & val
      if property.match /\[(.*?)\]/
        properties = _.filter(property.split(/\[(.*?)\]/), _.identity)
        property   = properties[0]
        [key, val] = properties[1].split('=')

      # If the property exists on the collection inspect it otherwise
      # it doesn't exist, and return undefined
      if _.has(collection, property) && !_.isUndefined(collection[property])
        # If the collection property is an Array and we have a key then
        # we need to look for the object within this collection with
        # the matching kay.val using filter - we then pop the first object
        # out of the filtered array and send it back
        if _.isArray(collection[property]) && !_.isUndefined key

          # Are we trying to inspect a DataItem like so?
          # DataItem[value=Mortgagee1AddressCityProper]
          # Identifier nodes also use the name / value structure
          # of DataItem
          if property == 'DataItem' || property == 'Identifier'
            return @findDataItem collection[property], val

          # Make a filter obj from key : val and use it in _.where
          # to find any objects in the collection array that match
          collection = _.where collection[property], _.object([key],[val])

          return @findProperty _.first(collection), _.rest(path)
        else
          return @findProperty collection[property], _.rest(path)

      else
        undefined

    # Find the specific value of a DataItem array, which is an array of
    # object containing name/val pairs: {name: 'foo', value: 'bar'}
    # NOTE: if the value is empty (ex: "") we return undefined
    findDataItem : (collection, name) ->
      if !_.isArray collection
        return undefined

      # We favor Op prefixed versions of DataItems, so we search for
      # these first
      op_name = "Op#{name}"
      data_item = _.where collection, { 'name' : op_name }

      if data_item.length == 0
        data_item = _.where collection, { 'name' : name }

      if data_item.length > 0
        data_item[0].value
      else
        undefined
