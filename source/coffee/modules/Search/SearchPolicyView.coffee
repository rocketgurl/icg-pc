define [
  'BaseView',
  'text!modules/Search/templates/tpl_search_policy_row.html'
], (BaseView, tpl_search_policy_row) ->

  SearchPolicyView = BaseView.extend

    tagName   : 'a'

    className : 'tr'

    initialize : (options) ->
      @controller = options.controller
      @el.id   = "#{@model.get('identifiers').policyId}-#{@cid}"

    render : ->
      data = @model.toJSON()
      data.effectiveDate = data.effectiveDate?.substr(0, 10) 
      data.policyStateClass = data.policyState.toLowerCase()
      data.renewalReviewRequired = if data.renewalReviewRequired is true then 'Yes' else 'No'
      data.insured.Address = @constructAddress data.insured.address
      href = @href = @constructHref data
      html = @Mustache.render tpl_search_policy_row, data
      @$el.attr('href', href).html html
      this

    constructAddress : (addressObj) ->
      {line1, city, state} = addressObj
      address = ''
      address += line1 if line1
      address += ', ' if line1 and city
      address += city if city
      address += ', ' if city and state
      address

    constructHref : (data) ->
      href = "##{@controller.baseRoute}/policy"
      href += "/#{data.identifiers.quoteNumber}"
      href

    openPolicy : ->
      @controller.Router.navigate @href, { trigger : true }

    # Remove view and deref what we can for GC
    destroy : ->
      @$el.remove()
      @model = null
      @el    = null
