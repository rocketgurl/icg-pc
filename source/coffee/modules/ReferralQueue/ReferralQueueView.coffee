define [
  'BaseView',
  'Helpers',
  'Messenger',
  'modules/ReferralQueue/ReferralTaskView',
  'modules/ReferralQueue/ReferralAssigneesModel',
  'text!modules/ReferralQueue/templates/tpl_referral_container.html',
  'text!modules/ReferralQueue/templates/tpl_manage_assignees.html'
], (BaseView, Helpers, Messenger, ReferralTaskView, ReferralAssigneesModel, tpl_container, tpl_menu_assignees) ->

  ReferralQueueView = BaseView.extend

    PAGINATION_EL : {} # Pagination form elements
    SORT_CACHE    : {} # Which column is sorted and direction
    OWNER_STATE   : '' # Used for 'My Referrals' switch

    events :
      "change .referrals-pagination-page" : -> 
        @paginateTasks(@COLLECTION, @PAGINATION_EL)
      "change .referrals-pagination-perpage" : -> 
        @paginateTasks(@COLLECTION, @PAGINATION_EL)
      "click .referrals-sort-link" : (e) ->
        @sortTasks(e, @COLLECTION)
      "click .referrals-switch li" : (e) ->
        @toggleOwner(e, @COLLECTION, @PAGINATION_EL)
      "click .button-manage-assignees" : (e) ->
        @toggleManageAssignees(e)
      "click .menu-confirm" : (e) ->
        @saveAssignees(e)
      "change input[type=checkbox]" : (e) ->
        @toggleCheckbox(e)
      "click .menu-cancel" : (e) ->
        @clearAssignees(e)

    initialize : (options) ->
      @MODULE      = options.module || false
      @COLLECTION  = options.collection || false
      @PARENT_VIEW = options.view || false
      
      ixlibrary    = options.ixlibrary || false

      # When the collection is populated, generate the views
      @COLLECTION.bind('reset', @renderTasks, this);
      @COLLECTION.bind('error', @tasksError, this);

      # Setup our DOM hooks
      @el  = @PARENT_VIEW.el
      @$el = @PARENT_VIEW.$el

      # Create an AssigneeList model to manage the XML list
      if @MODULE != false
        digest    = @MODULE.controller.user.get 'digest'
        ixlibrary = "#{@MODULE.controller.services.ixlibrary}buckets/underwriting/objects/assignee_list.xml"

      @AssigneeList     = new ReferralAssigneesModel({ digest : digest })
      @AssigneeList.url = ixlibrary
      errorCallback     = _.bind @renderAssigneesError, this
      @AssigneeList.fetch
        error : errorCallback

      @AssigneeList.on 'change', @assigneeSuccess, this 
      @AssigneeList.on 'fail', @assigneeError, this 

    render : ->
      # Setup flash module & main container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_container, { cid : @cid, pagination: {} }
      @$el.html html

      # Setup Flash Messenger
      @messenger = new Messenger(@PARENT_VIEW, @cid)

      # Find the container to load rows into
      @CONTAINER = @$el.find('table.module-referrals tbody')

      # Cache form elements for speedy access
      @PAGINATION_EL = @cachePaginationElements()

      # Throw up our loading image until the tasks come in
      @toggleLoader(true)

      # If we couldn't load assignee_list.xml then disable the button
      if @ASSIGNEE_STATE == false
        @$el.find('.button-manage-assignees').attr('disabled', true)

      this

    # **Render tasks**  
    # Map the collection models into an array of ReferralTaskViews that we
    # can use to populate the overall view with task rows.
    #
    # @param `collection` _Object_ ReferralTaskCollection  
    # @return _Array_  
    #
    renderTasks : (collection) ->
      @TASK_VIEWS = collection.map (model) => 
        new ReferralTaskView(
            model       : model,
            parent_view : this
          )

      @CONTAINER.html('')

      for task in @TASK_VIEWS
        @CONTAINER.append(task.render())

      @toggleLoader()
      @updatePagination(collection, @PAGINATION_EL)

      # Need to let the footer know that we changed height
      if _.has(@MODULE, 'trigger')
        @MODULE.trigger 'workspace.rendered'

    # Handle server errors from the Tasks Collection
    #
    # @param `collection` _Object_ ReferralTaskCollection  
    # @param `response` _jqXHR_ Response object  
    #
    tasksError : (collection, response) ->
      @toggleLoader()
      @Amplify.publish @cid, 'warning', "Could not load referrals: #{response.status} - #{response.statusText}"
      console.log ["tasksError", collection, response]

    # Toggle the owner field on the UI and trigger collection.getReferrals()
    #
    # @param `e` _Event_
    # @param `collection` _Object_ ReferralTaskCollection  
    # @param `elements` _Object_ Cached jQuery HTML Elements  
    #
    toggleOwner : (e, collection, elements) ->
      e.preventDefault()
      $el = $(e.currentTarget)

      query =
        perPage : elements.per_page.val() || 25
        page    : elements.jump_to.val() || 1

      if $el.hasClass('active')
        return
      else
        $('.referrals-switch').find('li').removeClass('active')
        $el.addClass('active')

        if $el.find('a').attr('href') == 'allreferrals'
          query.OwningUnderwriter = @OWNER_STATE =  ''
        else
          @OWNER_STATE = @options.owner

        @toggleLoader(true)
        collection.getReferrals(query)

    # Update the collection with values from pagination form
    #
    # @param `collection` _Object_ ReferralTaskCollection  
    # @param `elements` _Object_ jQuery wrapped HTML elements  
    #     
    paginateTasks : (collection, elements) ->
      query =
          perPage           : elements.per_page.val() || 25
          page              : elements.jump_to.val() || 1
          OwningUnderwriter : @OWNER_STATE

      @toggleLoader(true)
      collection.getReferrals(query)

    # Return an object of pagination form elements  
    # @return _Object_ 
    cachePaginationElements : ->
      items    : @$el.find('.pagination-a')
      jump_to  : @$el.find('.referrals-pagination-page')
      per_page : @$el.find('.referrals-pagination-perpage')
 

    # Update the pagination controls with current info
    #
    # @param `collection` _Object_ ReferralTaskCollection  
    # @param `elements` _Object_ jQuery wrapped HTML elements  
    # 
    updatePagination : (collection, elements) ->
      # Items count
      per_page = elements.per_page.val()

      # Coerce strings into actual numbers via destructuring
      [per_page, collection.totalItems, collection.page] = _.map([per_page, collection.totalItems, collection.page], (num) ->
          parseInt(num, 10)
        )

      if per_page > collection.totalItems
        end_position   = collection.totalItems
        start_position = 1
      else
        end_position   = collection.page * per_page
        start_position = end_position - per_page

      start_position = if start_position == 0 then 1 else start_position

      if end_position > collection.totalItems
        end_position = collection.totalItems

      elements.items.find('span').html("Items #{start_position} - #{end_position} of #{collection.totalItems}")

      # Jump to pages
      pages        = [1..Math.ceil(+collection.totalItems / elements.per_page.val())]
      current_page = parseInt(collection.page, 10)
      values       = _.map pages, (page) ->
        if page == current_page
          return $("<option value=\"#{page}\" selected>#{page}</option>")
        else
          return $("<option value=\"#{page}\">#{page}</option>")
      elements.jump_to.html(values)


    # Place a loading animation on top of the content
    toggleLoader : (bool) ->
      # If this is empty we're probably testing
      if $("#referrals-spinner-#{@cid}").length < 1
        return false

      if bool and !@loader?
        if $('html').hasClass('lt-ie9') is false
          @loader = Helpers.loader("referrals-spinner-#{@cid}", 100, '#ffffff')
          @loader.setDensity(70)
          @loader.setFPS(48)
        $("#referrals-loader-#{@cid}").show()
      else
        if @loader? and $('html').hasClass('lt-ie9') is false
          @loader.kill()
          @loader = null
        $("#referrals-loader-#{@cid}").hide()

    # Sort the current page of tasks in memory.
    #
    # @param `e` _Event_ Click event 
    # @param `collection` _Object_ ReferralTaskCollection   
    # 
    sortTasks : (e, collection) ->
      e.preventDefault()
      $el = $(e.currentTarget)

      @SORT_CACHE =
        'sort'    : $el.attr('href')
        'sortdir' : $el.data('dir')

      @remove_indicators() # clear the decks!

      collection.sortTasks(@SORT_CACHE.sort, @SORT_CACHE.sortdir)

      if $el.data('dir') is 'asc'
        $el.data('dir', 'desc')
        @swap_indicator $el, '&#9660;'
      else
        $el.data('dir', 'asc')
        @swap_indicator $el, '&#9650;'

    # Switch sorting indicator symbol  
    #
    # @param `el` _HTML Element_ table header  
    # @param `char` _String_ direction indicator  
    #    
    swap_indicator : (el, char) ->
      text = el.html()
      reg = /▲|▼/gi
      if text.match('▲') or text.match('▼')
        text = text.replace(reg, char)
        el.html(text)
      else
        el.html(text + " #{char}")

    # clear all sorting indicators
    remove_indicators : ->
      $('.referrals-sort-link').each (index, el) ->
        el = $(el)
        reg = /▲|▼/gi
        el.html(el.html().replace(reg, ''))

    # JSON data from AssigneeList needs some additional parsing to render
    # correctly in Mustache
    toggleManageAssignees : (e) ->
      e.preventDefault()
      if @AssigneeList.get('json')?
        assignees = @AssigneeList.parseBooleans(@AssigneeList.get('json').Assignee)
        @Modal.attach_menu $(e.currentTarget), '.rq-menus', tpl_menu_assignees, {assignees : assignees}
      else
        @Amplify.publish @cid, 'warning', "Unable to load assignees from server."

    renderAssigneesError : (model, xhr, options) ->
      @ASSIGNEE_STATE = false
      @Amplify.publish 'controller', 'warning', "Warning - could not load assignees xml: #{xhr.status} - #{xhr.statusText}"

    # The two lists of checkboxes are combined into one array of objects. Then
    # map over the Assignee JSON from the model, plucking objects from our
    # combined array with the same identity and merging in their new values.
    # The updated Assignee JSON is set back to the model, which generates XML
    # and PUTs it back to the server.
    #
    saveAssignees : (e) ->
      e.preventDefault()
      @assigneeLoader()
      values = []
      json   = @AssigneeList.get('json').Assignee

      # Combine lists into array with some processing on identity
      @$el.find('input[type=checkbox]').each (index, val) ->
        name = $(val).attr('name')
        if name.indexOf('newbiz_') > -1
          values.push
            identity     : name.replace /newbiz_/gi, ''
            new_business : $(val).val()
        else
          values.push
            identity : name.replace /renewal_/gi, ''
            renewals : $(val).val()

      merged = _.map json, (assignee) ->
        items = _.where values, { identity : assignee.identity }
        if items.length > 1
          _.extend assignee, items[0], items[1]
        else
          _.extend assignee, items[0]

      @AssigneeList.set 'json', { Assignee : merged }
      @AssigneeList.putList()

    # Remove the menu from DOM so it will be generated fresh erasing any
    # changes from the user
    clearAssignees : (e) ->
      e.preventDefault()
      @Modal.removeMenu()

    assigneeLoader : ->
      @$el.find('.menu-status')
          .show()
          .html('<strong class="menu-loading">Saving changes&hellip;</strong>')   

    assigneeSuccess : (model) ->
      @$el.find('.menu-status')
          .show()
          .html('<strong class="menu-success">Assignee List saved!</strong>')
          .delay(2000)
          .fadeOut('slow')

    assigneeError : (msg) ->
      @$el.find('.menu-status')
          .show()
          .html("""<strong class="menu-error">Error saving: #{msg}</strong>""")
          .delay(5000)
          .fadeOut('slow')

    toggleCheckbox : (e) ->
      $cb = $(e.currentTarget)
      if $cb.attr('checked')
        $cb.val('true')
      else
        $cb.val('false')
      $cb
  