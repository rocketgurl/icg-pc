define [
  'jquery',
  'amplify_core',
  'BaseModel'
], ($, amplify, BaseModel) ->

    # Global log object
    amplify.subscribe 'log', (msg) ->
      console.log "LOG: " + msg

    model = new BaseModel
      id : 1

    init: () ->      

      $(document).ready () ->
        $('a').on 'click', (e) ->
          e.preventDefault()
          model.logger 'I was clicked by ' + $(e.target).html()
          

      