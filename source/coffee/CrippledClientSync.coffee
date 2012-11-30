define [
  'jquery', 
  'underscore',
  'backbone'
], ($, _, Backbone) ->

  originalSync = Backbone.sync # need to mod the original

  #### Cripple Client
  #
  # ICS 360 moves data as **XML**, not JSON. Also, there are
  # legacy issues at play that require sending a lot of
  # custom headers to display error messaging, etc.
  #
  # We're monkey patching Backbone.sync to apply those
  # headers
  #
  CrippledClientSync = (method, model, options) ->

    methodMap =
      'create' : 'POST'
      'update' : 'PUT'
      'delete' : 'DELETE'
      'read'   : 'GET'

    type = methodMap[method]

    # We want to move XML back and forth, and use our own
    # XML parser (processData : false)
    options = _.extend options,
      dataType        : 'xml'
      contentType     : 'application/xml'
      processData     : false
      withCredentials : true # for CORS

    # Pass along auth information
    options.basic_auth_digest = model.get('digest') if model.get('digest')?

    # Append Crippled Client specific headers
    options.beforeSend = (xhr) ->
      xhr.setRequestHeader('X-Crippled-Client', 'yes')
      xhr.setRequestHeader('X-Rest-Method', type)
      xhr.setRequestHeader('X-Requested-With', 'XMLHTTPRequest')

      # !! **SUPER IMPORTANT** !!
      # If you don't spec the Accept for application/xml then you will not
      # get the correct version of Policy XML files
      #
      xhr.setRequestHeader('Accept', 'application/xml') 

      if options.basic_auth_digest
        xhr.setRequestHeader('X-Authorization', "Basic #{options.basic_auth_digest}")
        xhr.setRequestHeader('Authorization', "Basic #{options.basic_auth_digest}")

    originalSync.apply(Backbone, [ method, model, options ]) # Carry on Backbone...

  CrippledClientSync