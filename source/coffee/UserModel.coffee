define [
  'BaseModel'
], (BaseModel) ->

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
        @set {'digest' : @Helpers.createDigest @get('username'), @get('password')}
        delete @attributes.password

    # Additional document parsing to load up User with more accessible
    # information (pulling attrs out of parsed XML and into model.attributes)
    #
    parse_identity : () ->
      doc = @get 'document'
      if doc?
        @set 'passwordHash', doc.find('Identity').attr('passwordHash')
        @set 'name', doc.find('Identity Name').text()
        @set 'email', doc.find('Identity Email').text()
      
  UserModel

