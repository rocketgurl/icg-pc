define [
  'jquery', 
  'underscore',
  'mustache',
  'Helpers',
  'moment',
  'momentrange'
], ($, _, Mustache, Helpers, moment) ->

  class IPMFormValidation

    # Validators take the form of { element.name : rule name }
    validators : {}

    constructor : ->
      # Wrap validateField so if field validation responds false then we need 
      # to change the UI to display error state. We also remove that UI change 
      # when it does validate.
      @validateField = _.wrap @validateField, (func) =>
        args   = _.toArray arguments
        result = func(args[1], args[2], args[3])
        if result
          @showErrorState(args[1])
        else
          @removeErrorState(args)
          
        result

      # These functions need a jQuery wrapped element, so we
      # ensure they get one (DRY) by wrapping
      _.each ['showErrorState', 'removeErrorState'], (f) =>
        @[f] = _.wrap @[f], (func) =>
          args = _.toArray arguments
          if !(args[1] instanceof jQuery)
            args[1] = $(args[1])
          func(args[1], this)

    # Return an array of fields with errors
    #
    # @param `required_fields` _Array_ Form elements to be validated
    # @return _Array_ 
    #
    validateFields : (validate_fields) ->
      # Loop through array and test each field
      # Object || false
      fields = for el in validate_fields
                @validateField(el, @validators, this)
      # filters out false values
      (field for field in fields when field)

    # Validate a single form field
    #
    # @param `el` _HTML Element_ Form element to be validated
    # @return _Boolean_ || _Object_ **Note:** true means it failed
    #
    validateField : (el, validators, FormValidation) ->
      if !(el instanceof jQuery)
        el = $(el)

      el_name = el.attr('name')

      # Call the rule for this el if it has a definition
      if validators? && _.has(validators, el_name)
        for rule in validators[el_name]
          if res = FormValidation[rule](el)
            return res
        return false
      else
        return false

    # Build validator rule object of inputs with required rule 
    #
    # @param `inputs` _Array_ HTML Input Elements
    # @return _Object_  
    #
    processRequiredFields : (inputs) ->
      validators = {}
      for input in inputs
        input = $(input)
        validators[input.attr('name')] = ['required']
      validators

    # Merge the required fields validators object with any existing validators
    #
    # @param `required_fields` _Object_ Validators  
    # @param `validators` _Object_ Validators  
    # @param `form` _jQuery_ Form object    
    # @return _Object_  
    #
    mergeValidators : (required_fields, validators, form, form_cid) ->
      for name, rule of validators
        el = form.find "##{form_cid}_#{name}"
        if el.length > 0
          if _.has(required_fields, name)
            required_fields[name].push rule
            # _Hack_: because of the order we do this, another array may be
            # pushed onto this one, so we flatten it and remove dupes.
            # TODO: Refactor IPMActionView and FormValidation to only assemble
            # validation fields one time
            required_fields[name] = _.uniq(_.flatten(required_fields[name]))
          else
            required_fields[name] = [rule]
      required_fields


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
        .on('change', (el) => scope.validateField($(el.currentTarget)))
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
        $label = $(err.element).parent().find('label')
        $label.find('i').remove()
        "<li>#{$label.html()} - #{err.msg}</li>"

      """
        The fields below had errors that need correction:
        <div class="error_details">
          <ul>
            #{details.join('')}
          </ul>
        </div>
      """

    # Check a jQuery form element for an empty or unset state
    #
    # @param `el` _Form Element_  
    # @return _Boolean_  
    #      
    isEmpty : (el) ->
      val = el.val()
      val == '' || val == null || val == undefined

    # Rules
    # -----
    # TODO: Maybe wrap these in the jQuery checker up top
    required : (el) ->
      if @isEmpty el
        { element : el, msg : 'This is a required field' }
      else
        false

    dateRange : (el) ->
      if @isEmpty el
        return { element : el, msg : "Date missing" }

      start  = moment(el.data('minDate')).subtract('days', 1)
      end    = moment(el.data('maxDate')).add('days', 1)
      whence = moment(el.val())
      range  = moment().range(start, end)

      # We need to send the opposite boolen to pass _.filter()
      if whence.within(range)
        false 
      else
        { element : el, msg : "Outside date range: #{el.data('minDate')} - #{el.data('maxDate')}" }


    # We need to accept values of zero hence check against -1
    money : (el) ->
      if parseFloat(el.val(), 10) > -1
        false
      else
        { element : el, msg : "Needs to be at least zero" }

    # Determine if a number falls within a range. Only one attr (min/max)
    # needs to be defined.
    number : (el) ->
      val = parseInt(el.val(), 10)
      min = if el.attr('min') then parseInt(el.attr('min'), 10) else null
      max = if el.attr('max') then parseInt(el.attr('max'), 10) else null
      msg = { element : el, msg : "Outside range: #{el.data('min')} - #{el.data('max')}" }

      if min && val < min
        return msg
      if max && val > max
        return msg

      false
      
