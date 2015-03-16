define [
  'BaseCollection'
  'modules/Search/SearchPolicyModel'
], (BaseCollection, SearchPolicyModel) ->

  #### A collection of policies
  class SearchPolicyCollection extends BaseCollection

    model : SearchPolicyModel

    pageDefault : 1

    perPageDefault : 50

    policyStateDefault : null

    sortPropDefault : null

    sortDirDefault : null

    searchByDefault : null

    sortCache :
      'quote-number'   : 'desc'
      'policy-number'  : 'desc'
      'carrier-id'     : 'desc'
      'last-name'      : 'desc'
      'policy-state'   : 'desc'
      'effective-date' : 'desc'

    isValid : ->
      @q?.length > 1 or @renewalreviewrequired

    initialize : ->
      @searchBy = 'quote-policy-number'

    sync : (method, collection, options) ->
      if @isValid()
        options = _.extend options,
          cache   : false
          data    : @getParams()
          headers :
            'Authorization' : "Basic #{@controller.user.get('digest')}"
        @jqXHR = Backbone.sync method, collection, options
        @trigger 'request', this, @jqXHR
      else
        @trigger 'invalid', this, 'Search query length must be at least 2 characters'

    # Retrieve the policies from the response
    parse : (response) ->
      @page        = response.page
      @perPage     = response.perPage
      @totalItems  = response.totalItems
      @policyState = response.policystate if response.policystate
      response.policies

    getParams : ->
      params =
        page    : @page or @pageDefault
        perPage : @perPage or @perPageDefault
      params.q           = @q or ''
      params.searchby    = @searchBy    if @searchBy
      params.policystate = @policyState if @policyState
      params.sort        = @sortProp    if @sortProp
      params.sortdir     = @sortDir     if @sortDir
      if params.q?.length
        delete params.renewalreviewrequired
      else if @renewalreviewrequired
        params.renewalreviewrequired = @renewalreviewrequired
      params

    setParam : (param, value, silent) ->
      value = if value is 'default' then @["#{param}Default"] else value
      unless value is @[param]
        if value
          @[param] = value
        else
          value = null
          delete @[param]
        @trigger("update update:#{param}", this, value) unless silent

    sortBy : (property) ->
      if property is 'default'
        @sortProp = @sortPropDefault
        @sortDir  = @sortDirDefault
      else
        # swap the sort direction & store for later
        @sortDir = if @sortCache[property] is 'asc' then 'desc' else 'asc'
        @sortCache[property] = @sortDir
        @sortProp = property

      @trigger 'update update:sort', this, "#{@sortProp}:#{@sortDir}"

