define [
  'BaseView'
], (BaseView) ->

  WorkspaceNavView = BaseView.extend

    events :
      "click li a"                   : "toggle_main_nav"
      "click #workspace-subnav li a" : "toggle_sub_nav"

    initialize : (options) ->
      @$sub_el = $(options.sub_el)
      @$header = @options.controller.$workspace_header
      @base_height = @$header.height()

      # Hide the menus
      @$sub_el.hide()
      @$el.hide()

      # Attach even handler to Workspace Button - we have to do this
      # because we can't use the built-in Backbone events, since
      # our subnav is not in $el
      $('#header-controls').on 'click', '#button-workspace',(e) =>
        e.preventDefault()
        @toggle_nav_slide()

    render : () ->
      @$el.prepend(@options.main_nav)
      @$sub_el.html(@options.sub_nav)

      # Set height of sub_nav to main_nav
      @$sub_el.css 
        'min-height' : @$el.height()

    destroy : () ->
      @$el.find('.main-nav').remove()
      @$sub_el.empty()

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

    #### Toggle Sub Nav
    #
    # Toggle on/off main & subnav items
    #
    toggle_sub_nav : (e) ->
      e.preventDefault()
      $a = $(e.target) # stash link
      $li = $a.parent() # stash li
      @$sub_el.find('a').removeClass()
      $a.addClass('on')

      # Tell the Router to trigger the app
      @options.router.navigate($a.attr('href'), { trigger : true })

      @hide_nav()
      @toggle_nav_slide()


    #### Toggle Nav Slide
    #
    # Open and close the menus
    #
    toggle_nav_slide : () ->
      if @$header.height() is @base_height + 30 or @$header.height() is 65
        @$header.animate {
          height : 230 + @base_height # totally arbitrary height
          }, 200, 'swing', @show_nav()
      else
        @hide_nav()
        # determine correct close height based on presence of tabs
        close_height = @base_height
        if $('#workspace nav ul li').length > 0
          close_height = @base_height + 30

        @$header.animate {
          height : close_height
          }, 200, 'swing'

    #### Show Nav
    #
    # Slowly fade in the nav menus after opening
    #
    show_nav : () ->
      @$el.fadeIn('slow')
      @$sub_el.fadeIn('slow')

    #### Hide Nav
    #
    # Switch off menus, no fade.
    #
    hide_nav : () ->
      @$el.hide()
      @$sub_el.hide()


