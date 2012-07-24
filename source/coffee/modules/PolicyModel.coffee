define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  #### Policy
  #
  # We handle Policy XML here
  #
  PolicyModel = BaseModel.extend

    initialize : ->
      @use_cripple() # Use CrippledClient XMLSync

    url : ->
      return @get('urlRoot') + 'policies/' + @id

    get_pxServerIndex : ->
      doc = @get 'document'
      @set 'pxServerIndex', doc.find('Identifiers Identifier[name=pxServerIndex]').attr('value')

      
  PolicyModel