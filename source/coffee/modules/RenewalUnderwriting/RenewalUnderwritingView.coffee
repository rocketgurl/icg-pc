define [
  'BaseView',
  'Messenger',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_container.html',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_assignee.html',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_disposition.html',
  'jqueryui'
], (BaseView, Messenger, tpl_ru_container, tpl_ru_assignees, tpl_ru_disposition) ->

  RenewalUnderwritingView = BaseView.extend

    CHANGESET  : {}
    DATEPICKER : ''

    events :
      'click a[href=assigned_to]' : (e) -> 
        @changeAssignment(@process_event e)

      'click a[href=current_disposition]' : (e) -> 
        @changeDisposition(@process_event e)

      'click a[href=review_period]' : (e) -> 
        @reviewPeriod(@process_event e)

      'click a[href=review_deadline]' : (e) -> 
        @reviewDeadline(@process_event e)

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
      @loader = @Helpers.loader("ru-spinner-#{@policy_view.cid}", 80, '#696969')
      @loader.setFPS(48)
      
      # This is just for testing the loader, remove delay
      load = _.bind(@policy.fetchRenewalMetadata, @policy)
      _.delay(load, 1000)

      this # so we can chain

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

    reviewPeriod : (el) ->
      @$el.find('input[name=reviewPeriod]').datepicker("show")

    reviewDeadline : (el) ->
      @$el.find('input[name=reviewDeadline]').datepicker("show")

    attachDatepickers : ->

      @dateChanged   = _.bind(@dateChanged, this)
      @setDatepicker = _.bind(@setDatepicker, this)

      options =
        dateFormat : 'yy-mm-dd'
        onClose    : @dateChanged
        beforeShow : @setDatepicker

      @$el.find('input[name=reviewPeriod]').datepicker(options)
      @$el.find('input[name=reviewDeadline]').datepicker(options)

    # Get the field information from the HTML Element in DATEPICKER and pass
    # to processChange to see if we need to save anything.  
    # @param `field` _String_ name of CHANGESET field 
    dateChanged : (date) ->
      field = "renewal.#{$(@DATEPICKER).attr('name')}"
      if @processChange field, date
        @Amplify.publish(@policy_view.cid, 'success', "Saved changes!", 2000)

    # **Did a value change?**  
    # Check the CHANGESET to see if a value changed. For the field we check
    # for the existence of a '.' and split on that to deal with deeper values
    # in the CHANGESET.  
    #
    # @param `field` _String_ name of CHANGESET field  
    # @param `val` _String_ value of field that changed  
    # @return _Boolean_
    processChange : (field, val) ->
      old_val = ''
      field = if field.indexOf('.') > -1 then field.split('.') else field
      if _.isArray(field)
        old_val = @CHANGESET[field[0]][field[1]]
      else
        old_val = field

      if old_val != val
        # This is where we would save the value to the server
        console.log("CHANGED: #{field} to #{val}")
        true
      else
        console.log("NO CHANGE")
        false

    # Set the value of DATEPICKER for use in determining changes.  
    # @param `el` _HTML Element_  
    setDatepicker : (el) ->
      @DATEPICKER = el

    renewalSuccess : (resp) ->
      if resp?
        resp.cid = @cid

        # Store a changeset to send back to server
        @CHANGESET =
          renewal : _.omit(resp.renewal, ["inspectionOrdered", "renewalReviewRequired"])
          insuranceScore : resp.insuranceScore.currentDisposition

        @$el.html @Mustache.render tpl_ru_container, resp
        @removeLoader()
        @show()
        @attachDatepickers()

    renewalError : (resp) ->
      @Amplify.publish(@policy_view.cid, 'warning', "Could not retrieve renewal underwriting information: #{resp.statusText} (#{resp.status})")



