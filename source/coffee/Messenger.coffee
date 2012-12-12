define [
  'jquery', 
  'underscore'
], ($, _) ->

  #### Common inteface to flash messages using Amplify.js
  #
  class Messenger

    # jQuery animation options for flash messages
    animation_options :
      default :
        start :
          top : "+=115"
        end :
          top : "-=115"
      nomove :
        start : false
        end   : false

    # Create an Amplify sub for a specific view
    #
    # @param `view` _Object_ Backbone Parent View
    # @param `id` _String_ CID of view
    #
    constructor : (@view, @id) ->
      if @view.$el?
        @flash_message = @view.$el.find("#flash-message-#{@id}")
      else
        @flash_message = @view.find("#flash-message-#{@id}")
        
      @container = $(".flash-message-container")
      if @container.length == 0
        @container = $("#flash-message-controller")

      @register @id


    # Register an Amplify sub. Also sets up listener
    # to close the flash message
    #
    # @param `id` _String_ CID of view
    #
    register : (id) ->
      amplify.subscribe id, (type, msg, delay, animation) =>
        if animation?
          animation = @animation_options[animation]
        else 
          animation = @animation_options.default

        # set className
        if type?
          @flash_message.addClass type
        if msg?
          msg = """<span><i class="icon-remove-sign"></i>#{msg}</span>"""
          @container.show()  
          @flash_message.html(msg)
            .show()
            .animate({
                  opacity : 1
                  }, 500)
          @container.animate(animation.start, 500)


          # After a short delay remove the flash message
          if delay?
            _.delay =>
              @flash_message.html(msg)
                .animate({
                  opacity : 0
                  }, 500)
              @container.animate(animation.end, 500, ->
                  $(this).hide()
                )  
            , delay

    
        @flash_message.on 'click', (e) =>
          e.preventDefault()
          @flash_message.animate({
                opacity : 0
              }, 300)
          @container.animate(animation.end, 300, ->
              $(this).hide()
            )

        # Attach click handler to error message options list
        @flash_message.on 'click', '.error_details a', (e) =>
          e.preventDefault()
          $(this).next().toggle()
          $(this).toggle(
            ->
              $(this).html('<i class="icon-plus-sign"></i> Hide error details')
            ,
            ->
              $(this).html('<i class="icon-plus-sign"></i> Show error details')
          )
