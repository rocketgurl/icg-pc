define [
  'BaseView',
  'text!modules/Search/templates/tpl_search_policy_row.html'
], (BaseView, tpl_search_policy_row) ->

  SearchPolicyView = BaseView.extend

    className : 'tr'

    events :
      "click" : "open_policy"

    initialize : (options) ->
      @data       = options.model.toJSON()
      @controller = options.controller
      @el.id  = "#{@data.identifiers.policyId}-#{@cid}"
      @render()

    # Attach view to table
    render : ->
      # Chomp dates
      @data.effectiveDate = @data.effectiveDate.substr(0,10) if @data.effectiveDate?

      # Change UI on PolicyState label using className
      @data.policyStateClass = @data.policyState.toLowerCase()

      if @data.renewalReviewRequired?
        @data.renewalReviewRequired = if @data.renewalReviewRequired == true then 'Yes' else 'No'
      else
        @data.renewalReviewRequired = 'No'

      # Deal with address concatenation
      @data.insured.Address = ""
      if @data.insured.address.line1?
        @data.insured.Address += "#{@data.insured.address.line1}, "
      if @data.insured.address.city?
        @data.insured.Address += "#{@data.insured.address.city}, "

      @$el.html @Mustache.render tpl_search_policy_row, @data
      @options.$target_el.append @$el
      this

    # Remove view and deref what we can for GC
    destroy : ->
      @$el.remove()
      @model = null
      @el    = null

    # Open a new PolicyView tab with the current policy
    open_policy : (e) ->
      e.preventDefault() if _.isObject e

      identifiers = @model.get 'identifiers'
      last_name = @model.get('insured').lastName or ''

      # Setup the params object to launch policy view with
      policyLabel = identifiers.policyId or identifiers.quoteNumber
      
      params =
        url     : identifiers.quoteNumber
        label : "#{last_name} #{policyLabel}"

      @controller.launch_module 'policyview', params
      @controller.Router.append_module 'policyview', params
