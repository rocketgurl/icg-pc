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
    views : []

    # Retrieve the policies from the response
    parse: (response) ->
      response.policies;


    render : () ->
      @.each (model) =>
        @views.push new SearchPolicyView(
            model     : model
            container : @container
          )

  SearchPolicyCollection