define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  # Decorator: Make sure we have all we need to process method
  # which means a workspace object and an XML doc
  check_workspace = (methodBody) ->
    (workspace) ->
      # No document, no dice
      if not @get('document')?
        false
      # Extract workspace config from model
      workspace = workspace.get('workspace')
      if !workspace?
        false
      else
        methodBody.apply(this, arguments)

  #### Configs
  #
  # We handle ixAdmin configuration properties here
  #
  ConfigModel = BaseModel.extend

    initialize : () ->
      @use_xml() # Use XMLSync
      @urlRoot = @get 'urlRoot'

    # Get SWF information from config file based on
    # workspace configuration
    get_config : 
      check_workspace \
      (workspace) ->
        doc    = @get('document')
        config = doc.find("ConfigItem[name=#{workspace.app}] ConfigItem[name=businesses] ConfigItem[name=#{workspace.business}] ConfigItem[name=#{window.ICS360_ENV}]")
        serializer = new XMLSerializer()
        
        if config[0]? 
          @set 'swf_config', serializer.serializeToString(config[0])
          return @get('swf_config')
        else
          false

    # Try to find the popServer with the config XML file
    # we use this to set which pxCentral we're going to hit
    get_pxCentral : 
      check_workspace \
      (workspace) ->
        doc = @get('document')
        url = doc.find("ConfigItem[name=#{workspace.app}] ConfigItem[name=businesses] ConfigItem[name=#{workspace.business}] ConfigItem[name=#{window.ICS360_ENV}] ConfigItem[name=popServer] ConfigItem[name=baseURL]").attr('value')

        if url is undefined then false else url

    # Retrieve baseURL of service from <universalServices> config
    get_universal_service :
      check_workspace \
      (workspace, service) ->
        doc = @get('document')
        url = doc.find("ConfigItem[name=#{workspace.app}] ConfigItem[name=businesses] ConfigItem[name=#{workspace.business}] ConfigItem[name=#{window.ICS360_ENV}] ConfigItem[name=universalServices] ConfigItem[name=#{service}] ConfigItem[name=baseURL]").attr('value')

        if url is undefined then false else url

      
  ConfigModel