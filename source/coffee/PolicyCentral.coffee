define [
  'jquery',
  'amplify_core',
  'WorkspaceRouter'
], ($, amplify, WorkspaceRouter) ->

    # Global log object
    amplify.subscribe 'log', (msg) ->
      console.log "LOG: " + msg

    init: () ->      
      router = new WorkspaceRouter()
          