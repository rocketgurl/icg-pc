define [
  'jquery', 
  'underscore',
  'mustache',
  'Helpers',
  'moment',
  'momentrange'
], ($, _, Backbone, Mustache, Helpers, moment) ->

  class IPMFormValidation

    # Validators take the form of { element.name : rule name }
    #
    # @param `validators` _Object_ rules hash per action 
    #
    constructor : (@validators) ->

      # If a field does not validate (come back as true) then we
      # send need to mark it in the UI - send back a Boolean!
      @validateField = _.wrap @validateField, (func) =>
        args = _.toArray arguments
        if func(args[1])
          @showErrorState(args[1])
          true # error!
        else
          @removeErrorState(args[1])
          false # passes

      # These functions need a jQuery wrapped element, so we
      # ensure they get one (DRY)
      _.each ['showErrorState', 'removeErrorState'], (f) =>
        @[f] = _.wrap @[f], (func) =>
          args = _.toArray arguments
          if !(args[1] instanceof jQuery)
            args[1] = $(args[1])
          func(args[1], this)

    # Return an array of validated form fields
    #
    # @param `arr` _Array_ Form elements to be validated
    # @return _Array_ 
    #
    validateFields : (arr) ->
      _.filter arr, (el) =>
        @validateField(el)

    # Validate a single form field
    #
    # @param `el` _HTML Element_ Form element to be validated
    # @return _Boolean_ 
    #
    validateField : (el) ->
      if !(el instanceof jQuery)
        el = $(el)

      # _Note:_ true means it failed
      if el.val() == '' || el.val() == undefined
        return true

      el_name = el.attr('name')

      # Call the rule for this el if it has a definition
      if @validators? && _.has(@validators, el_name)
        return @[@validators[el_name]](el)
      else
        return false

    # Elements should show that they are required. We also attach an
    # event so that if the element is 'changed' it is re-validated on the fly
    #
    # @param `el` _HTML Element_ Form element to be validated  
    # @param `scope` _this_ Optional scope element (callback village)      
    # @return _HTML Element_ 
    #
    showErrorState : (el, scope) ->
      scope = scope ? this
      el.addClass('validation_error')
        .on('change', (el) =>
          scope.validateField $(el.currentTarget)
        )
        .parent()
        .find('label')
        .addClass('validation_error')
      el

    # Remove the error class from elements
    #
    # @param `el` _HTML Element_ Form element to be validated   
    # @return _HTML Element_  
    #
    removeErrorState : (el) ->
      if el.hasClass 'validation_error'
        el.removeClass('validation_error')
          .parent()
          .find('label')
          .removeClass('validation_error')
      el

    # Assemble the error message for the view
    #
    # @param `errors` _Array_ offending elements  
    # @return _String_ HTML fragment 
    #  
    displayErrorMsg : (errors) ->
      details = _.map errors, (err) ->
        "<li>#{$(err).parent().find('label').html()}</li>"

      """
        Please complete the required fields below
        <div class="error_details">
          <ul>
            #{details.join('')}
          </ul>
        </div>
      """


    # Rules
    # -----

    dateRange : (el) ->
      start  = moment(el.data('minDate')).subtract('days', 1)
      end    = moment(el.data('maxDate')).add('days', 1)
      whence = moment(el.val())
      range  = moment().range(start, end)

      whence.within(range);


    money : (el) ->
      parseFloat(el.val()) > 0