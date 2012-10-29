define [
  'BaseView',
  'Helpers',
  'Messenger',
  'modules/ReferralQueue/ReferralTaskView',
  'text!modules/ReferralQueue/templates/tpl_referral_container.html'
], (BaseView, Helpers, Messenger, ReferralTaskView, tpl_container) ->

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

    initialize : (options) ->
      @MODULE        = options.module || false
      @COLLECTION    = options.collection || false
      @PARENT_VIEW   = options.view || false

      # When the collection is populated, generate the views
      @COLLECTION.bind('reset', @renderTasks, this);

      # Setup our DOM hooks
      @el  = @PARENT_VIEW.el
      @$el = @PARENT_VIEW.$el

    render : ->
      # Setup flash module & main container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_container, { cid : @cid, pagination: {} }
      @$el.html html

      # Find the container to load rows into
      @CONTAINER = @$el.find('table.module-referrals tbody')

      # Cache form elements for speedy access
      @PAGINATION_EL = @cachePaginationElements()

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

    toggleOwner : (e, collection, elements) ->
      e.preventDefault()
      $el = $(e.currentTarget)
      console.log $el

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
      end_position = collection.page * elements.per_page.val()
      start_position = end_position - elements.per_page.val()
      start_position = if start_position == 0 then 1 else start_position
      elements.items.find('span').html("Items #{start_position} - #{end_position} of #{collection.totalItems}")

      # Jump to pages
      pages        = _.range(1, Math.round(collection.totalItems / elements.per_page.val()))
      current_page = parseInt(collection.page, 10)
      values       = _.map pages, (page) ->
        if page == current_page
          return $("<option value=\"#{page}\" selected>#{page}</option>")
        else
          return $("<option value=\"#{page}\">#{page}</option>")
      elements.jump_to.html(values)


    # Place a loading animation on top of the content
    toggleLoader : (bool) ->
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

