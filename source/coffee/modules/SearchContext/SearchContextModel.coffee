define [
  'BaseModel'
], (BaseModel) ->

  #### A Policy used in Search views
  #
  SearchContextModel = BaseModel.extend

    initialize : ->
      @use_localStorage 'ics_saved_searches'

  SearchContextModel