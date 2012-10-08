define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_renewal_underwriting_container.html',
  'text!templates/tpl_renewal_underwriting_assignee.html',
  'text!templates/tpl_renewal_underwriting_disposition.html'
], (BaseView, Messenger, tpl_ru_container, tpl_ru_assignees, tpl_ru_disposition) ->

  RenewalUnderwritingView = BaseView.extend

    events :
      'click a[href=assigned_to]' : (e) -> 
        @changeAssignment(@process_event e)

      'click a[href=current_disposition]' : (e) -> 
        @changeDisposition(@process_event e)

      'click .menu-close' : (e) ->
        @clear_menu e

    initialize : (options) ->
      @$el         = options.$el
      @policy      = options.policy
      @policy_view = options.policy_view

      @policy.on 'renewal:success', @renewalSuccess, this
      @policy.on 'renewal:error', @renewalError, this

    render : ->
      @show()
      $("#ru-loader-#{@policy_view.cid}").show()
      console.log($("#ru-loader-#{@policy_view.cid}"))
      @loader = @Helpers.loader("ru-spinner-#{@policy_view.cid}", 80, '#696969')
      @loader.setFPS(48)
      load = _.bind(@policy.fetchRenewalMetadata, @policy)
      _.delay(load, 2000)

    removeLoader : ->
      @loader.kill()
      $("#ru-loader-#{@cid}").hide()

    show : ->
      @$el.fadeIn('fast')

    hide : ->
      @$el.hide()

    process_event : (e) ->
      e.preventDefault()
      $(e.currentTarget)

    # Render a menu and attach it to el. Only create the menu once.
    attach_menu : (el, template, view_data) ->
      container = el.parent()
      menu      = container.find('.ru-menus')
      if menu.length == 0
        menu = @Mustache.render template, view_data
        container.append(menu).find('div').fadeIn(200)
      else
        menu.fadeIn('fast')

      @overlay_trigger container.find('.ru-menus')

    # Remove menu
    clear_menu : (e) ->
      if e.currentTarget?
        $(e.currentTarget).parents('.ru-menus').fadeOut(100)
      else
        e.fadeOut('fast')

      $('.ru-overlay').remove()

    # Drops a transparent div underneath menu to act as trigger to remove
    # the menu
    overlay_trigger : (@menu) ->
      overlay = $("<div></div>")
                  .addClass('ru-overlay')
                  .css({
                    width      : '100%'
                    height     : '100%'
                    position   : 'absolute'
                    zIndex     : 640
                    background : 'transparent'
                  })

      $('body').prepend(overlay)
      $(overlay).on 'click', (e) =>
        @clear_menu @menu

    # Stub data for changeAssignment menu
    changeAssignment : (el) ->
      data = 
        cid : @cid
        assignees : [
          { id : 1, name : 'Alice' }
          { id : 2, name : 'Bob' }
          { id : 3, name : 'Cipher' }
        ]

      @attach_menu el, tpl_ru_assignees, data


    changeDisposition : (el) ->
      data = 
        cid : @cid
        dispositions : [
          { id : 1, name : 'Pending' }
          { id : 2, name : 'Dead' }
          { id : 3, name : 'Vaporized' }
        ]

      @attach_menu el, tpl_ru_disposition, data

    renewalSuccess : (resp) ->
      if resp?
        resp.cid = @cid
        console.log resp
        @$el.html @Mustache.render tpl_ru_container, resp
        @removeLoader()
        @show()

    renewalError : (resp) ->
      @Amplify.publish(@policy_view.cid, 'warning', "Could not retrieve renewal underwriting information: #{resp.statusText} (#{resp.status})")

