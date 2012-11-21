define [
  'jquery', 
  'underscore',
  'mustache'
], ($, _, Mustache) ->

  class ModalHelper

    constructor : ->
      @Mustache = Mustache

    # Attach modal window to view
    #
    # @param `el` _HTML Element_ Element which triggered menu    
    # @param `className` _String_ class to hook menu onto  
    # @param `template` _String_ Mustache template for menu    
    # @param `view_data` _Object_  
    # @return _HTML Element_ menu     
    #
    attach_menu : (@el, @className, @template, view_data) ->
      container = @el.parent()
      menu      = container.find(@className)
      if menu.length == 0
        menu = @Mustache.render template, view_data
        container.append(menu).find('div').fadeIn(200)
      else
        menu.fadeIn('fast')

      @overlay_trigger container.find(className)

      menu

    # Remove menu
    clear_menu : (e) ->
      if e.currentTarget?
        $(e.currentTarget).parents(@className).fadeOut(100)
      else
        e.fadeOut('fast')

      $('.modal-overlay').remove()

    # Drops a transparent div underneath menu to act as trigger to remove
    # the menu
    overlay_trigger : (menu) ->
      overlay = $("<div></div>")
                  .addClass('modal-overlay')
                  .css({
                    width      : '100%'
                    height     : '100%'
                    position   : 'absolute'
                    zIndex     : 640
                    background : 'transparent'
                  })

      $('body').prepend(overlay)
      $(overlay).on 'click', (e) =>
        @clear_menu menu