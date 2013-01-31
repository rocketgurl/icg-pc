define [
  'BaseModel',
  'modules/Search/SearchContextView'
], (BaseModel, SearchContextView) ->

  #### A Policy used in Search views
  #
  SearchContextModel = BaseModel.extend

    initialize : ->
      @use_localStorage 'ics_saved_searches'

      data = @attributes

      # Help out herp derp browsers
      if _.isObject data.params
        data.params = @Helpers.serialize data.params

      view = new SearchContextView(
          parent     : @collection.menu
          data       : data
          controller : @collection.controller
          model      : this
        )
