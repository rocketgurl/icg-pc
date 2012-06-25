define [
  'BaseView'
], (BaseView) ->

  WorkspaceNavView = BaseView.extend

    events :
      "click li a" : "toggle_main_nav"

    initialize : (options) ->
      @$sub_el = $(options.sub_el)

    render : () ->
      @$el.prepend(@options.main_nav)
      @$sub_el.html(@options.sub_nav)

      # Set height of sub_nav to main_nav
      @$sub_el.css 
        'min-height' : @$el.height()

    #### Toggle Main Nav
    #
    # Toggle on/off main & subnav items
    #
    toggle_main_nav : (e) ->
      e.preventDefault()

      $a = $(e.target).parent() # stash link
      $li = $a.parent() # stash li
      $li.addClass('open')
      $li.siblings().removeClass 'open' # Toggle all main nav items off

      # Toggle subnav on/off
      @$sub_el.find("##{$a.data('pc')}").removeClass()
      @$sub_el.find("##{$a.data('pc')}").siblings().addClass('sub_nav_off')
