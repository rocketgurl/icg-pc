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
      @use_cripple() # Use CrippledClient XMLSync

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
      
  UserModel

