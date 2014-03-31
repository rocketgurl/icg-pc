define [
  'BaseView',
  'text!modules/Search/templates/tpl_search_policy_row.html'
], (BaseView, tpl_search_policy_row) ->

  SearchPolicyView = BaseView.extend

    tagName : 'tr'

    events :
      "click" : "open_policy"

    # We need to brute force the View's container to the
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @data   = options.model.attributes
      @parent = options.container.$el
      @target = @parent.find('table.module-search tbody')
      @module = options.model.collection.container.module
      @render()

    # Attach view to table
    render : ->
      @$el.attr
        id : @data.identifiers.InsightPolicyId

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
      @target.append @$el

    # Remove view and deref what we can for GC
    destroy : ->
      @$el.remove()
      @model = null
      @el    = null

    # Open a new PolicyView tab with the current policy
    open_policy : (e) ->
      e.preventDefault()
      $el = $(e.currentTarget)

      identifiers = @model.get('identifiers')
      last_name = @model.get('insured').lastName || ""

      # Setup the params object to launch policy view with
      if identifiers.policyId? then policyLabel = identifiers.policyId else policyLabel = identifiers.quoteNumber 
      
      params =
        url     : identifiers.quoteNumber
        label : last_name + " " + policyLabel

      @module.view.options.controller.launch_module 'policyview', params
      @module.view.options.controller.Router.append_module 'policyview', params
