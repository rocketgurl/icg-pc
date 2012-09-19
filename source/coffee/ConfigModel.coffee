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

    get_config : (workspace) ->
      if not @get('document')?
        false

      doc        = @get('document')
      config     = doc.find("ConfigItem[name=#{workspace.app}] ConfigItem[name=businesses] ConfigItem[name=#{workspace.business}] ConfigItem[name=#{window.ICS360_ENV}]")
      serializer = new XMLSerializer()

      if config[0]? 
        @set 'swf_config', serializer.serializeToString(config[0])
        return @get('swf_config')
      else
        false


      
  ConfigModel