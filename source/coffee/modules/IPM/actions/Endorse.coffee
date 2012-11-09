define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class EndorseAction extends IPMActionView

    # Custom calculations objects
    COVERAGE_CALCULATIONS : {}

    initialize : ->
      super

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'endorse', @processView)

    # **Build a viewData object to populate the template form with**  
    #
    # Takes the model.json and creates a custom data object for this view. We
    # then set that object to @viewData and the view to @view and trigger the
    # `loaded` event passing @postProcessView as the callback. This will
    # attach any necessary behaviors to the rendered form.  
    #
    # @param `vocabTerms` _Object_ model.json  
    # @param `view` _String_ HTML template    
    #
    processView : (vocabTerms, view) =>
      super vocabTerms, view

      viewData = @MODULE.POLICY.getTermDataItemValues(vocabTerms)
      viewData = @MODULE.POLICY.getEnumerations(viewData, vocabTerms)

      viewData = _.extend(
        viewData,
        @MODULE.POLICY.getPolicyOverview(),
        { 
          policyOverview : true
          policyId : @MODULE.POLICY.get_pxServerIndex()
        }
      )

      @viewData = viewData
      @view     = view

      @trigger "loaded", this, @postProcessView

    render : (viewData, view) ->
      super
      viewData = viewData || @viewData
      view     = view || @view
      @$el.html(@MODULE.VIEW.Mustache.render(view, viewData))


    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      # @@ Action specific processing
      @VALUES.formValues.positivePaymentAmount = \
        Math.abs(@VALUES.formValues.paymentAmount || 0)

      @VALUES.formValues.paymentAmount = \
        -1 * @VALUES.formValues.positivePaymentAmount

      # Assemble the ChangeSet XML and send to server
      @CHANGE_SET.commitChange(
          @CHANGE_SET.getPolicyChangeSet(@VALUES)
          @callbackSuccess,
          @callbackError
    # Add Coverage Calulation behaviors to Endorse forms
    postProcessView : ->
      super

      # Attach coverage.change event to inputs
      @$el.find('input').bind 'coverage:calculate', @calculateCoverage

      # Bind listener to <select>s that alter other fields
      @$el.find('select[data-affects]').bind 'change', @triggerCoverageCalculation

      # Bind listener specifically to CoverageA <input>
      @$el.find('input[name=CoverageA]').bind 'input', (e) =>
        @triggerAllCoverageCalculations()
        @deriveCoverageACalculations()

      # Find any custom calculations tucked away in data attrs for later
      # use in calculations
      coverage_a = @$el.find('input[name=CoverageA]')
      if coverage_a.length > 0
        if data = coverage_a.data 'calculations'
          @COVERAGE_CALCULATIONS = (eval("(#{data})"))
        )
    # Recalculate the value of the element relative to CoverageA.  
    # _Note_: The value is not the percentage in the label but the
    # enumeration value which is percentage * 100 
    #
    # @param `e` _Event_  
    # @param `val` _Integer_  
    #
    calculateCoverage : (e, val) =>
      coverage_a = parseInt(@$el.find('input[name=CoverageA]').val(), 10)
      new_value  = Math.round((coverage_a * val) / 10000);
      $(e.currentTarget).val(new_value);

    # When a <select> with a data-affects attr is changed we need to find the
    # input that it affects (data-affects) and trigger a coverage:calculate 
    # event passing in the value of this <select> 
    #
    # @param `e` _Event_  
    #
    triggerCoverageCalculation : (e) =>
      el = $(e.currentTarget)
      @$el.find("input[name=#{el.data('affects')}]").trigger(
          'coverage:calculate',
          el.val()
        )

    # Loop through all <select>s with data-affects and trigger
    # coverage:calculate  
    #
    triggerAllCoverageCalculations : ->
      @$el.find('select[data-affects]').each (index, el) =>
        el = $(el)
        if el.val()
          @$el.find("input[name=#{el.data('affects')}]").trigger(
            'coverage:calculate',
            el.val()
          )

    # If CoverageA is present as well as @COVERAGE_CALCULATIONS then
    # loop through the cached calcs and do the math on CoverageA's
    # value, setting the new value back to the element that needs is.
    #
    # _Example:_      
    # CoverageCalc is { CoverageD : '.2' } so get the value of 
    # CoverageA and multiply it by .2, then apply that value to
    # the <input> for CoverageD.
    #
    deriveCoverageACalculations : ->
      if !_.isEmpty @COVERAGE_CALCULATIONS
        coverage_a = @$el.find('input[name=CoverageA]')
        if coverage_a.length > 0 || coverage_a.val()?
          value_a = coverage_a.val()
          for key, val of @COVERAGE_CALCULATIONS
            calc_val = value_a * parseFloat val
            @$el.find("input[name=#{key}]").val calc_val

