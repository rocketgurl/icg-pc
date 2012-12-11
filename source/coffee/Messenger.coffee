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
      amplify.subscribe id, (type, msg, delay, animation) =>
        if animation?
          animation = @animation_options[animation]
        else 
          animation = @animation_options.default

        # set className
        if type?
          @flash_container.addClass type
        if msg?
          msg = """<span><i class="icon-remove-sign"></i>#{msg}</span>"""
          @flash_container.html(msg)
            .animate({
                  opacity : 1
                  }, 500)
          @flash_container.parent().animate(animation.start, 500)


          # After a short delay remove the flash message
          if delay?
            _.delay =>
              @flash_container.html(msg)
                .animate({
                  opacity : 0
                  }, 500)
              @flash_container.parent().animate(animation.end, 500)  
            , delay

    
        @flash_container.on 'click', (e) =>
          e.preventDefault()
          @flash_container.animate({
                opacity : 0
              }, 300)
          @flash_container.parent().animate(animation.end, 300)

        # Attach click handler to error message options list
        @flash_container.on 'click', '.error_details a', (e) =>
          e.preventDefault()
          $(this).next().toggle()
          $(this).toggle(
            ->
              $(this).html('<i class="icon-plus-sign"></i> Hide error details')
            ,
            ->
              $(this).html('<i class="icon-plus-sign"></i> Show error details')
          )
