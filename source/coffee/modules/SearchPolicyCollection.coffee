define [
  'BaseCollection',
  'modules/SearchPolicyModel',
  'modules/SearchPolicyView',
  'base64'
], (BaseCollection, SearchPolicyModel, SearchPolicyView, Base64) ->

  #### A collection of policies
  #
  SearchPolicyCollection = BaseCollection.extend

    model : SearchPolicyModel
    views : [] # view stack

    # Retrieve the policies from the response
    parse: (response) ->
      response.policies;

    # We need to reset the table so that future searches
    # won't append tables to the existing result set.
    render : () ->
      $('table.module-search tbody').html('')
      @views = []
      @populate()

    # Load table with policy views
    populate : ->
      @.each (model) =>
        @views.push new SearchPolicyView(
            model     : model
            container : @container
          )

  SearchPolicyCollection