define [
  'BaseView'
  'Helpers'
  'Messenger'
  'text!modules/ReferralQueue/templates/tpl_referral_container.html'
  'text!modules/ReferralQueue/templates/tpl_referral_task_row.html'
  'text!templates/tpl_pagination.html'
], (BaseView, Helpers, Messenger, tpl_container, tpl_row, tpl_pagination) ->

  class ReferralQueueView extends BaseView

    baseTemplate : _.template(tpl_container)

    rowTemplate : _.template(tpl_row)

    paginationTemplate : _.template(tpl_pagination)

    perPageOpts : [15, 25, 50, 75, 100]

    events :
      'change .pagination-page'     : 'onPageChange'
      'change .pagination-perpage'  : 'onPerPageChange'
      'change input[name=status]'   : 'onStatusChange'
      'click .owner-switch a'       : 'onOwnerSwitchClick'
      'click .referrals-sort-link'  : 'sortTasks'
      'click .referrals-refresh'    : 'refreshTasks'
      'click .abort'                : 'abortRequest'

    initialize : (options) ->
      _.bindAll(this
        'toggleLoader'
        'tasksSuccessCallback'
        'tasksErrorCallback'
        )

      @PARENT_VIEW           = options.view || false
      @MODULE                = options.module || false
      @collection            = options.collection || false
      @collection.controller = options.module.controller
      @collection.on 'request', => @toggleLoader true
      @collection.on 'reset', @tasksSuccessCallback
      @collection.on 'error', @tasksErrorCallback

    cacheElements : ->
      @$header       = @$('header.module-referrals')
      @$table        = @$('.div-table.module-referrals')
      @$tHead        = @$table.find '.thead'
      @$tBody        = @$table.find '.tbody'
      @$paginationEl = @$('.pagination')

    attachWindowResizeHandler : ->
      lazyResize = _.debounce _.bind(@setTbodyMaxHeight, this), 500
      $(window).on 'resize', lazyResize

    setTbodyMaxHeight : ->
      workspaceHeight    = @MODULE.controller.$workspace_el.height()
      headerHeight       = @$header.outerHeight()
      theadHeight        = @$tHead.outerHeight()
      tbodyMaxHeight     = workspaceHeight - (headerHeight + theadHeight)
      @$tBody.css 'max-height', tbodyMaxHeight

    render : ->
      # Setup flash module & main container
      @$el.html(@baseTemplate({
        cid        : @cid
        pagination : @paginationTemplate @determinePagination()
      }))

      @cacheElements()
      @setTbodyMaxHeight()
      @attachWindowResizeHandler()

      # Setup Flash Messenger
      @messenger = new Messenger(@PARENT_VIEW, @cid)

      # Throw up our loading image until the tasks come in
      @toggleLoader true

      this

    # **Render tasks**
    # Map the collection models into an array of ReferralTaskViews that we
    # can use to populate the overall view with task rows.
    #
    # @param `collection` _Object_ ReferralTaskCollection
    # @return _Array_
    #
    renderTasks : (collection) ->
      rows = collection.map (model) =>
        @rowTemplate model.toJSON()
      @$tBody.html rows.join('\n')

      # Need to let the footer know that we changed height
      if _.has(@MODULE, 'trigger')
        @MODULE.trigger 'workspace.rendered'

    renderPagination : ->
      html = @paginationTemplate @determinePagination()
      @$paginationEl.html html

    refreshTasks : ->
      @toggleLoader true
      @collection.fetch()

    abortRequest : ->
      if jqXHR = @collection.jqXHR
        jqXHR.abort()

    tasksSuccessCallback : (collection) ->
      @toggleLoader()
      @renderTasks collection
      @renderPagination()

    tasksErrorCallback : (collection, response) ->
      @toggleLoader false
      if response?.statusText is 'abort'
        @Amplify.publish @cid, 'notice', "Request canceled.", 3000
      else
        @Amplify.publish @cid, 'warning', "Could not load referrals: #{response.status} - #{response.statusText}"
        @logError collection, response

    logError : (collection, response) ->
      # Log a hopefully useful ajax error for TrackJS
      info = ""
      try
        info = """
ReferralQueue XMLHTTPResponse Error (#{response.status}) #{response.statusText}
RequestURL: #{collection.url}
RequestParams: #{$.param(collection.getParams())}
ResponseHeaders: #{response.getAllResponseHeaders()}
        """
        throw new Error "IPM Action Error"
      catch ex
        console.info info

    onPageChange : (e) ->
      @updatePage +e.currentTarget.value

    updatePage : (page) ->
      if page > 0
        @collection.setParam 'page', page
        @collection.fetch()

    onPerPageChange : (e) ->
      @updatePerPage +e.currentTarget.value

    updatePerPage : (perPage) ->
      if perPage > 0
        @collection.setParam 'perPage', perPage
        @collection.setParam 'page', 'default'
        @collection.fetch()

    onStatusChange : (e) ->
      showAll = $(e.currentTarget).prop 'checked'
      status = if showAll then null else 'default'
      @updateStatus status

    updateStatus : (status) ->
      @collection.setParam 'status', status
      @collection.setParam 'page', 'default'
      @collection.fetch()

    onOwnerSwitchClick : (e) ->
      e.preventDefault()
      $btn = $(e.currentTarget)
      unless $btn.hasClass 'active'
        $('.owner-switch > a').removeClass 'active'
        $btn.addClass 'active'
        owner = if $btn.attr('href') is 'myreferrals' then 'default' else null
        @updateOwner owner

    updateOwner : (owner) ->
      @collection.setParam 'owner', owner
      @collection.setParam 'page', 'default'
      @collection.fetch()

    determinePagination : ->
      params      = @collection.getParams()
      currentPage = params.page
      perPage     = params.perPage
      totalItems  = @collection.totalItems or 0

      if totalItems > 0
        pages = [1..Math.ceil(totalItems / perPage)]
      else
        pages = [1]

      if totalItems is 0
        start = 0
        end = 0
      else if perPage > totalItems
        end   = totalItems
        start = 1
      else
        end   = currentPage * perPage
        start = end - perPage + 1

      start = 0 if start < 1
      end = totalItems if end > totalItems
      pagination =
        currentPage : currentPage
        perPage     : perPage
        perPageOpts : @perPageOpts
        totalItems  : totalItems
        pages       : pages
        start       : start
        end         : end

    # Place a loading animation on top of the content
    toggleLoader : (bool) ->
      # If this is empty we're probably testing
      if $("#referrals-spinner-#{@cid}").length < 1
        return false

      if bool and !@loader?
        @loader = Helpers.loader("referrals-spinner-#{@cid}", 100, '#ffffff')
        @loader.setDensity 70
        @loader.setFPS 48
        $("#referrals-loader-#{@cid}").show()
      else
        if @loader?
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

      @collection.sortTasks sortProp
      @remove_indicators()

      if @collection.sortDir is 'asc'
        $sortIcon.addClass 'glyphicon-chevron-down'
      else
        $sortIcon.addClass 'glyphicon-chevron-up'

    # clear all sorting indicators
    remove_indicators : ->
      $('.referrals-sort-link').each ->
        $icon = $(this).find '.glyphicon'
        $icon.removeClass 'glyphicon-chevron-up'
        $icon.removeClass 'glyphicon-chevron-down'

