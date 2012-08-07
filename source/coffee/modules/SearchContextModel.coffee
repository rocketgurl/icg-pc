define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  #### A Policy used in Search views
  #
  SearchContextModel = BaseModel.extend

    initialize : ->
      @use_localStorage 'ics_saved_searches'

  SearchContextModel