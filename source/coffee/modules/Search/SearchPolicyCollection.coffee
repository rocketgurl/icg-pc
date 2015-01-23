define [
  'BaseCollection'
  'modules/Search/SearchPolicyModel'
], (BaseCollection, SearchPolicyModel) ->

  #### A collection of policies
  class SearchPolicyCollection extends BaseCollection

    model : SearchPolicyModel

    pageDefault : 1

    perPageDefault : 50

    policystateDefault : null

    sortPropDefault : null

    sortDirDefault : null

    sortCache :
      'quote-number'   : 'desc'
      'policy-number'  : 'desc'
      'carrier-id'     : 'desc'
      'last-name'      : 'desc'
      'policy-state'   : 'desc'
      'effective-date' : 'desc'

    isValid : ->
      @q?.length > 1 or @renewalreviewrequired

    sync : (method, collection, options) ->
      if @isValid()
        options = _.extend options,
          data    : @getParams()
          headers :
            'Authorization' : "Basic #{@controller.user.get('digest')}"
        Backbone.sync method, collection, options
        @trigger 'request', this
      else
        @trigger 'invalid', this, 'Search query length must be at least 2 characters'

    # Retrieve the policies from the response
    parse : (response) ->
      @page        = response.page
      @perPage     = response.perPage
      @totalItems  = response.totalItems
      @policystate = response.policystate if response.policystate
      response.policies

    getParams : ->
      params =
        page    : @page or @pageDefault
        perPage : @perPage or @perPageDefault
      params.q           = @q or ''
      params.policystate = @policystate if @policystate
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

