define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  #### Configs
  #
  # We handle ixAdmin configuration properties here
  #
  ConfigModel = BaseModel.extend

    initialize : () ->
      @use_xml() # Use XMLSync
      @urlRoot = @get 'urlRoot'

      
  ConfigModel