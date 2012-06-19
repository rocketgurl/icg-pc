define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  #### User
  #
  # We handle ixDocument identities here
  #
  UserModel = BaseModel.extend

    initialize : () ->
      @use_xml()

      @urlRoot = @get 'urlRoot'

      # Username is ID
      if @get 'username'
        @id = @get 'username'

      # Create a digest for basic auth and remove password
      if @get('username') and @get('password')
        @set {'digest' : Base64.encode "#{@get('username')}:#{@get('password')}"}
        delete @attributes.password

    # Additional document parsing to load up User with more accessible
    # information (pulling attrs out of parsed XML and into model.attributes)
    #
    parse_identity : () ->
      doc = @get 'document'
      if doc?
        _.each ['Name', 'Email', '-passwordHash'], (key) =>
          if doc.Identity[key]?
            name = key.toLowerCase().replace /-/, ''
            @set name, doc.Identity[key]


    # Response state (Hackety hack hack)
    # 
    # Since we're on **Crippled Client**, all requests come back as
    # 200's and we have to do header parsing to ascertain what 
    # is actually going on. We stach the jqXHR in the model and
    # do some checking to see what the error code really is, then
    # stash that in the model as 'fetch_state'
    #
    response_state : () ->
      xhr = @get 'xhr'
      fetch_state =
        text : xhr.getResponseHeader 'X-True-Statustext'
        code : xhr.getResponseHeader 'X-True-Statuscode'
      @set 'fetch_state' : fetch_state
      
  UserModel

