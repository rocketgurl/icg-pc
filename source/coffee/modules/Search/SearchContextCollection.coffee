define [
  'BaseCollection',
  'modules/Search/SearchContextModel',
  'modules/Search/SearchContextView',
  'base64',
  'Store',
  'LocalStorageSync',
  'Helpers',
  'mustache',
  'text!modules/Search/templates/tpl_search_menu_views.html'
], (BaseCollection, SearchContextModel, SearchContextView, Base64, Store, LocalStorageSync, Helpers, Mustache, tpl_search_menu_views) ->

  #### Use Local Storage to handle saved search views
  #
  SearchContextCollection = BaseCollection.extend
    model        : SearchContextModel
    activeView   : null
    menu         : null
    localStorage : new Store 'ics_saved_searches'
    sync         : LocalStorageSync
    rendered     : false

    # Bind some events to deal with peculiarities of handling
    # multiple methods.
    #
    initialize : ->
      @menu = $(Mustache.render(tpl_search_menu_views, {}))

    getMenu : (view) ->
      @activeView = view
      @menu

    closeMenu : ->
      if @activeView?
        @activeView.clear_menus()
        @activeView.controls.removeClass('active')

    # Destroy the model and then remove from the collection.
    destroy : (id) ->
      model = @get id
      if model.destroy()
        @remove model