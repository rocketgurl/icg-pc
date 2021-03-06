define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  # Decorator: Make sure we have all we need to process method
  # which means a workspace object and an XML doc
  check_workspace = (methodBody) ->
    (workspace) ->
      # No document, no dice
      return false unless @get('document')?

      # Extract workspace config from model
      return false if _.isEmpty(workspace) || !workspace?

      workspace = workspace.get('workspace')
      if workspace == null || workspace == undefined
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

        if url == undefined then false else url

    # Create an object of configs for ixLibrary. FNIC seems to be missing some
    get_ixLibrary :
      check_workspace \
      (workspace) ->
        doc = @get('document')
        node = doc.find("ConfigItem[name=#{workspace.app}] ConfigItem[name=businesses] ConfigItem[name=#{workspace.business}] ConfigItem[name=#{window.ICS360_ENV}] ConfigItem[name=popServer] ConfigItem[name=library]")

        config =
          baseURL               : node.find("ConfigItem[name=baseURL]").attr('value')
          attachmentsBucket     : node.find("ConfigItem[name=attachmentsBucket]").attr('value')
          underwritingBucket    : node.find("ConfigItem[name=underwritingBucket]").attr('value')
          assigneeListObjectKey : node.find("ConfigItem[name=assigneeListObjectKey]").attr('value')

        if config == undefined then false else config

    # Retrieve baseURL of service from <universalServices> config
    get_universal_service :
      check_workspace \
      (workspace, service) ->
        doc = @get('document')
        url = doc.find("ConfigItem[name=#{workspace.app}] ConfigItem[name=businesses] ConfigItem[name=#{workspace.business}] ConfigItem[name=#{window.ICS360_ENV}] ConfigItem[name=universalServices] ConfigItem[name=#{service}] ConfigItem[name=baseURL]").attr('value')

        if url == undefined then false else url

    get_agent_support :
      check_workspace \
      (workspace) ->
        doc = @get('document')
        url = doc.find("ConfigItem[name=#{workspace.app}] ConfigItem[name=businesses] ConfigItem[name=#{workspace.business}] ConfigItem[name=#{window.ICS360_ENV}] ConfigItem[name=agentSupportViewURL]").attr('value')

        if url == undefined then false else url

    get_agent_portal_notices :
      check_workspace \
      (workspace) ->
        # doc = @get('document')
        # url = doc.find("ConfigItem[name=#{workspace.app}] ConfigItem[name=businesses] ConfigItem[name=#{workspace.business}] ConfigItem[name=#{window.ICS360_ENV}] ConfigItem[name=agentPortalNoticesURL]").attr('value')

        # if url == undefined then false else url

        config = {}
        if workspace.business is 'cru'
          config.baseURL = '/agentportal/'
          config.program = 'P4-CRU'
        else if workspace.business is 'fnic'
          config.baseURL = '/agentportal-fnic/'
          config.program = 'P1-FNIC'

        if _.isEmpty config then false else config

    # Retrieve URL of pxClient from ixConfig - pxClient is stored on S3
    get_pxClient :
      check_workspace \
      (workspace) ->
        doc = @get('document')
        url = doc.find("ConfigItem[name=policycentral] ConfigItem[name=policySummaryUrl]").attr('value')
        if url == undefined then false else url

  ConfigModel