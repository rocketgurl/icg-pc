define [
  'BaseModel'
], (BaseModel) ->

  #### A Policy used in Search views
  #
  SearchPolicyModel = BaseModel.extend

    parse : (resp) ->
      data = @normalizeCarrierId resp
      data.effectiveDate    = data.effectiveDate?.substr(0, 10)
      data.policyStateClass = data.policyState.toLowerCase()
      data.renewalUwStatus  = if data.renewalReviewRequired is true then 'Yes' else 'No'
      data.insured.Address  = @constructAddress data.insured.address
      data

    initialize : ->
      @set 'href', "##{@collection.controller.baseRoute}/policy/#{@get('identifiers').quoteNumber}"

    normalizeCarrierId : (data={}) ->
      if data.carrierId
        data.CarrierId = data.carrierId
      unless data.CarrierId
        data.CarrierId = '--'
      data

    constructAddress : (addressObj) ->
      {line1, city, state} = addressObj
      address = ''
      address += line1 if line1
      address += ', ' if line1 and city
      address += city if city
      address += ', ' if city and state
      address

  SearchPolicyModel