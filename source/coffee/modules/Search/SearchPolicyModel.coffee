define [
  'BaseModel'
], (BaseModel) ->

  #### A Policy used in Search views
  #
  SearchPolicyModel = BaseModel.extend

    parse : (resp) ->
      data = @normalizeCarrierId resp
      data

    normalizeCarrierId : (data) ->
      if data.carrierId
        data.CarrierId = data.carrierId
      unless data.CarrierId
        data.CarrierId = '--'
      data

  SearchPolicyModel