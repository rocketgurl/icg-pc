define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  UserModel = BaseModel.extend

    initialize : () ->
      @use_xml()

      # Username is ID
      if @get 'username'
        @id = @get 'username'

      # Create a digest for basic auth and remove password
      if @get('username') and @get('password')
        @set {'digest' : Base64.encode "#{@get('username')}:#{@get('password')}"}
        delete @attributes.password


  UserModel

