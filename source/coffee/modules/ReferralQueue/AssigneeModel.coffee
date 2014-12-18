define [
  'backbone'
], (Backbone) ->

  class AssigneeModel extends Backbone.Model

    parse : (data) ->
      if _.has data, 'new_business'
        data.new_business = @strToBool data.new_business
      if _.has data, 'renewals'
        data.renewals = @strToBool data.renewals
      if _.has data, 'active'
        data.active = @strToBool data.active
      data

    # Turn string representations of booleans into actual booleans.
    strToBool : (value) ->
      if value.constructor is String
        value.toLowerCase() is 'true'
      else if value.constructor is Boolean
        value
      else
        false

    setActiveAttribute : ->
      if (@get('renewals') is true) or (@get('new_business') is true)
        @set 'active', true
      else
        @set 'active', false

