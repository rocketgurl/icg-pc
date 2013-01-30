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
      @data.EffectiveDate = @data.EffectiveDate.substr(0,10) if @data.EffectiveDate?

      # Change UI on PolicyState label using className
      @data.policyStateClass = @data.PolicyState.toLowerCase()

      if @data.RenewalReviewRequired?
        @data.RenewalReviewRequired = if @data.RenewalReviewRequired == true then 'Yes' else 'No'
      else
        @data.RenewalReviewRequired = 'No'

      # Deal with address concatenation
      @data.insured.Address = ""
      if @data.insured.InsuredMailingAddressLine1?
        @data.insured.Address += "#{@data.insured.InsuredMailingAddressLine1}, "
      if @data.insured.InsuredMailingAddressCity?
        @data.insured.Address += "#{@data.insured.InsuredMailingAddressCity}, "

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

      # Setup the params object to launch policy view with
      params =
        url     : identifiers.QuoteNumber

      @module.view.options.controller.launch_module 'policyview', params
      @module.view.options.controller.Router.append_module 'policyview', params
