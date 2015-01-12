define [
  'BaseView'
  'Helpers'
  'Messenger'
  'modules/ReferralQueue/ReferralTaskView'
  'text!modules/ReferralQueue/templates/tpl_referral_container.html'
], (BaseView, Helpers, Messenger, ReferralTaskView, tpl_container) ->

  ReferralQueueView = BaseView.extend

    PAGINATION_EL : {} # Pagination form elements

    events :
      'change .referrals-pagination-page'    : 'updatePage'
      'change .referrals-pagination-perpage' : 'updatePerPage'
      'change input[name=show-all]'          : 'updateStatus'
      'click .referrals-switch a'            : 'updateOwner'
      'click .referrals-sort-link'           : 'sortTasks'

    initialize : (options) ->
      _.bindAll(this
        'toggleLoader'
        'renderTasks'
        'tasksError'
        )

      @MODULE      = options.module || false
      @COLLECTION  = options.collection || false
      @PARENT_VIEW = options.view || false

      # When the collection is populated, generate the views
      @COLLECTION.on 'update', => @toggleLoader true
      @COLLECTION.on 'reset', @renderTasks
      @COLLECTION.on 'error', @tasksError

    render : ->
      # Setup flash module & main container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_container, { cid : @cid, pagination: {} }
      @$el.html html

      # Setup Flash Messenger
      @messenger = new Messenger(@PARENT_VIEW, @cid)

      # Find the container to load rows into
      @CONTAINER = @$('table.module-referrals tbody')

      # Cache form elements for speedy access
      @PAGINATION_EL = @cachePaginationElements()

      @$('.launch-manage-assignees').removeClass('disabled').prop('disabled', false)

      # Throw up our loading image until the tasks come in
      @toggleLoader(true)

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

    # Toggle the owner buttons on the UI and trigger collection.getReferrals()
    updateOwner : (e) ->
      e.preventDefault()
      $btn = $(e.currentTarget)

      unless $btn.hasClass 'active'
        $('.referrals-switch > a').removeClass 'active'
        $btn.addClass 'active'

        if $btn.attr('href') is 'myreferrals'
          @COLLECTION.setParam 'owner', 'default'
        else
          @COLLECTION.setParam 'owner', null

    updatePage : (e) ->
      page = +e.currentTarget.value
      if page > 0
        @COLLECTION.setParam 'page', page

    updatePerPage : (e) ->
      perPage = +e.currentTarget.value
      if perPage > 0
        @COLLECTION.setParam 'perPage', perPage

    updateStatus : (e) ->
      showAll = $(e.currentTarget).prop 'checked'
      if showAll
        @COLLECTION.setParam 'status', null
      else
        @COLLECTION.setParam 'status', 'default'

    # Return an object of pagination form elements
    # @return _Object_
    cachePaginationElements : ->
      items    : @$('.pagination-a')
      jump_to  : @$('.referrals-pagination-page')
      per_page : @$('.referrals-pagination-perpage')

    # Update the pagination controls with current info
    #
    # @param `collection` _Object_ ReferralTaskCollection
    # @param `elements` _Object_ jQuery wrapped HTML elements
    #
    updatePagination : (collection, elements) ->
      # Items count
      per_page = collection.perPage

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
      pages        = [1..Math.ceil(collection.totalItems / per_page)]
      current_page = collection.page
      values       = _.map pages, (page) ->
        if page is current_page
          "<option value=\"#{page}\" selected>#{page}</option>"
        else
          "<option value=\"#{page}\">#{page}</option>"
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
    sortTasks : (e) ->
      e.preventDefault()
      $el = $(e.currentTarget)
      $sortIcon = $el.find '.glyphicon'
      sortProp = $el.attr 'href'

      @COLLECTION.sortTasks sortProp
      @remove_indicators()

      if @COLLECTION.sortDir is 'asc'
        $sortIcon.addClass 'glyphicon-chevron-down'
      else
        $sortIcon.addClass 'glyphicon-chevron-up'

    # clear all sorting indicators
    remove_indicators : ->
      $('.referrals-sort-link').each ->
        $icon = $(this).find '.glyphicon'
        $icon.removeClass 'glyphicon-chevron-up'
        $icon.removeClass 'glyphicon-chevron-down'

