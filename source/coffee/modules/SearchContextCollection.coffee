define [
  'modules/SearchContextModel',
  'modules/SearchContextView',
  'base64',
  'Store',
  'LocalStorageSync',
  'amplify',
  'Helpers',
  'json'
], (SearchContextModel, SearchContextView, Base64, Store, LocalStorageSync, Amplify, Helpers, JSON) ->

  #### A collection of policies
  #
  SearchContextCollection = Backbone.Collection.extend

    Amplify      : Amplify
    model        : SearchContextModel
    views        : [] # view stack
    localStorage : new Store 'ics_saved_searches'
    sync         : LocalStorageSync
    rendered     : false

    # Use Local Storage to hand saved search views
    initialize : () ->
      @bind 'add', @add_one, @
      @bind 'reset', @add_many, @

    add_one : (model) ->
      console.log 'add one' 
      @render model

    add_many : (collection) ->
      collection.each (model) =>
        @render model

    # We need to reset the table so that future searches
    # won't append tables to the existing result set.
    render : (model, parent) ->
      @parent = parent || $('.search-menu-context')
      data = model.attributes

      # Help out herp derp browsers
      if _.isObject data.params
        data.params = Helpers.serialize data.params

      #data.params = Helpers.serialize data.params
      model.view = new SearchContextView(
          parent : @parent
          data   : data
        )

    populate : (html) ->
      @each (model) =>
        @render model, html
