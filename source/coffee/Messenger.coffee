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
          top : "15px"
        end :
          top : "-15px"
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

      @container = @findContainer(@view)
      @register @id


    # Look through the view and find our container with some checking for
    # different types of containers
    findContainer : (view) ->
      if view.$el?
        view = view.$el

      container = view.find(".flash-message-container")
      if container.length == 0
        container = view.find("#flash-message-controller")

      container


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
          @flash_message.html(msg)

          options = _.extend animation.start, { opacity : 1 }
          @container.show().animate(options, 500)  

          console.log @container
    
          # After a short delay remove the flash message
          if delay?
            _.delay =>
              options = _.extend animation.end, { opacity : 0 }
              @container.animate(options, 500, ->
                  $(this).hide()
                )   
            , delay

        # On click fade it out immediately without moving and then reset to
        # default position
        @flash_message.on 'click', (e) =>
          e.preventDefault()
          options = { opacity : 0 }
          @container.animate(options, 200, ->
              $(this).hide()
              if _.has animation.end, 'top'
                $(this).css('top', '-100px')
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
