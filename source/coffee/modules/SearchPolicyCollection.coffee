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

    # If we have existing views, kill them.
    # Otherwise load up the new ones.
    render : () ->
      if @views.length > 0
        for view in @views
          view.destroy()
          @views.shift()
        @populate()
      else
        @populate()

    # Load table with policy views
    populate : ->
      @.each (model) =>
        @views.push new SearchPolicyView(
            model     : model
            container : @container
          )

  SearchPolicyCollection