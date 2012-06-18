define [
  'jquery',
  'amplify_core',
  'WorkspaceController',
  'WorkspaceRouter',
  'BaseModel'
], ($, amplify, WorkspaceController, WorkspaceRouter, BaseModel) ->

    # Global log object
    amplify.subscribe 'log', (msg) ->
      console.log "LOG: " + msg

    # Insight 360 Services
    ics360 =
      services :
        ixdirectory : './ixdirectory/api/rest/v2/'
        pxcentral   : './pxcentral/api/rest/v1/'
        ixlibrary   : './ixlibrary/api/sdo/rest/v1/'
        ixdoc       : './ixdoc/api/rest/v2/'

    model = new BaseModel()

    Workspace =
      Controller : WorkspaceController
      Router     : new WorkspaceRouter()

    init: () ->      
      model.switch_sync 'xmlSync'
      model.parse = model.xmlParse
      # model.id = 1
      # model.logger model.id
      # model.fetch()
      # model.set
      #   name : 'Holmers'
      # console.log model.save()
      # model.logger model.get 'name'
      model.id = 'tim@arc90.com'
      model.url = 'mocks/user_tim_c.xml'
      model.set({'digest' : 'dGltQGFyYzkwLmNvbTpwYXNzdGltMjI='})
      model.fetch()
      console.log model

      console.log model.attributes

      # model.use_localStorage()
      # model.id = 1
      # model.fetch()
      # model.logger model.get 'name'
      # console.log model

      #console.log model.xmlParse('<?xml version="1.0" encoding="iso-8859-1"?><labels></labels>') 
          