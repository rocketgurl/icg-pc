define [
  'BaseView'
], (BaseView) ->

  WorkspaceNavView = BaseView.extend

    events :
      "click .main-nav > li > a"     : "toggle_main_nav"
      "click #workspace-subnav li a" : "toggle_sub_nav"

    initialize : (options) ->
      _.bindAll this, 'toggle_nav_slide'

      @$sub_el = $(options.sub_el)
      @$header = @options.controller.$workspace_header
      @base_height = @$header.height()

      # Attach even handler to Workspace Button - we have to do this
      # because we can't use the built-in Backbone events, since
      # our subnav is not in $el
      $('#button-workspace').off('click').on 'click', @toggle_nav_slide
      @render()

    render : ->
      @$el.prepend(@options.main_nav)
      @$sub_el.html(@options.sub_nav)
      @setState()

    # Ensure that the navigation indicates current state
    setState : ->
      current_state = @options.controller.current_state
      if _.isEmpty current_state
        @$('#workspace-subnav li a').removeClass()
        @$('li a[data-pc]').first().click()
      else
        {env, business, context, app} = current_state
        @$("li a[data-pc=#{business}]").click()
        @$("#nav-#{env}-#{business}-#{context}-#{app}").addClass('on')

    destroy : ->
      @$el.find('.main-nav').remove()
      @$el.hide()
      @$sub_el.empty()
      @off()
      @undelegateEvents()

    #### Toggle Main Nav
    #
    # Toggle on/off main & subnav items
    #
    toggle_main_nav : (e) ->
      e.preventDefault()

      $a = $(e.currentTarget)
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
      $a = $(e.currentTarget)
      @$sub_el.find('a').removeClass()
      $a.addClass 'on'
      @toggle_nav_slide()

    #### Toggle Nav Slide
    #
    # Open and close the menus
    #
    toggle_nav_slide : (e) ->
      e.preventDefault() if _.isObject e
      @$el.slideToggle()

    #### Show Nav
    #
    # Slowly fade in the nav menus after opening
    #
    show_nav : ->
      @$el.slideDown()

    #### Hide Nav
    #
    # Switch off menus, no fade.
    #
    hide_nav : ->
      @$el.slideUp()

