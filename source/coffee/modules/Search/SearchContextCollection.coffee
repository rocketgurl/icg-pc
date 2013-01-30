define [
  'BaseCollection',
  'modules/Search/SearchContextModel',
  'modules/Search/SearchContextView',
  'base64',
  'Store',
  'LocalStorageSync',
  'Helpers'
], (BaseCollection, SearchContextModel, SearchContextView, Base64, Store, LocalStorageSync, Helpers) ->

  #### Use Local Storage to handle saved search views
  #
  SearchContextCollection = BaseCollection.extend
    model        : SearchContextModel
    views        : [] # view stack
    localStorage : new Store 'ics_saved_searches'
    sync         : LocalStorageSync
    rendered     : false

    # Bind some events to deal with peculiarities of handling
    # multiple methods.
    #
    initialize : ->
    #   @bind 'add', @add_one, @
    #   @bind 'reset', @add_many, @

    # add_one : (model) ->
    #   @render model

    # add_many : (collection) ->
    #   collection.each (model) =>
    #     @render model

    # Create a view for the model and slot into all of the
    # existing menus in the UI.
    #
    # We can take raw HTML here instead of a className (parent)
    #
    render : (model, menu, search_view) ->
      menu = menu ? $('.search-menu-context')
      data = model.attributes

      # Help out herp derp browsers
      if _.isObject data.params
        data.params = Helpers.serialize data.params

      model.view = new SearchContextView(
          parent      : menu
          data        : data
          controller  : @controller
          collection  : this
          search_view : search_view
        )

    populate : (menu, search_view) ->
      $('.search-menu-context tbody tr').not('.renewalreviewrequired').remove()
      @each (model) =>
        @render model, menu, search_view

    # Destroy the model and then remove from the collection.
    destroy : (id) ->
      model = @get id
      if model.destroy()
        @remove model