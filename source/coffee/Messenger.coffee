define [
  'jquery', 
  'underscore'
], ($, _) ->

  #### Common inteface to flash messages using Amplify.js
  #
  class Messenger

    # Create an Amplify sub for a specific view
    #
    # @param `view` _Object_ Backbone Parent View
    # @param `id` _String_ CID of view
    #
    constructor : (@view, @id) ->
      if @view.$el?
        @flash_container = @view.$el.find("#flash-message-#{@id}")
      else
        @flash_container = @view.find("#flash-message-#{@id}")
        
      @register @id


    # Register an Amplify sub. Also sets up listener
    # to close the flash message
    #
    # @param `id` _String_ CID of view
    #
    register : (id) ->
      amplify.subscribe id, (type, msg, delay) =>
        # set className
        if type?
          @flash_container.addClass type
        if msg?
          msg += ' <i class="icon-remove-sign"></i>'
          @flash_container.html(msg).fadeIn('fast')

          # After a short delay remove the flash message
          if delay?
            _.delay =>
              @flash_container.html(msg).fadeOut('slow')            
            , delay

    

      @flash_container.on 'click', 'i', (e) =>
        e.preventDefault()
        @flash_container.fadeOut 'fast'

