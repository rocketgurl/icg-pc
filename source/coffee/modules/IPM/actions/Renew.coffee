define [
  'modules/IPM/IPMActionView',
  'modules/IPM/actions/Endorse'
], (IPMActionView, Endorse) ->

  ###
  # Renew is very similar to Endorse so where possible we try and
  # re-use Endorse methods (parseIntervals)
  ###
  class RenewAction extends IPMActionView

    initialize : ->
      super

      # We need Endorse to use parseIntervals
      @Endorse = new Endorse({
        PARENT_VIEW : @PARENT_VIEW
        MODULE      : @MODULE
      })

      @coverage_calculations     = {} # Custom calculations objects
      @transaction_request_xml   = null
      @override_validation_state = false # used to override rate validation
      @events =
        "click fieldset h3" : "toggleFieldset"

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'renew', @processView)

    # **Build view data objects and trigger loaded event**
    #
    # Takes the model.json and creates a custom data object for this view. We
    # then trigger the `loaded` event passing @postProcessView as the callback.
    # This will attach any necessary behaviors to the rendered form.
    #
    # @param `vocabTerms` _Object_ model.json
    # @param `view` _String_ HTML template
    #
    processView : (vocabTerms, view) =>
      @processViewData(vocabTerms, view)
      @trigger "loaded", this, @postProcessView

    # **Apply behaviors to default form after rendering**
    #
    # * Add Coverage Calulation behaviors
    #
    postProcessView : ->
      super

      # Attach coverage.change event to inputs
      @$el.find('input').bind 'coverage:calculate', @calculateCoverage

      # Bind listener to <select>s that alter other fields
      @$el.find('select[data-affects]').bind 'change', @triggerCoverageCalculation

      # We do a lot of magic with CoverageA
      @coverage_a = @$el.find('input[name=CoverageA]')

      # Bind listener specifically to CoverageA <input>
      @coverage_a.bind 'input', (e) =>
        @triggerAllCoverageCalculations()
        @deriveCoverageACalculations()
        #@adjustHO3VAWaterBackupCoverage()

      # Find any custom calculations tucked away in data attrs for later
      # use in calculations
      if @coverage_a.length > 0
        if data = @coverage_a.data 'calculations'
          @coverage_calculations = (eval("(#{data})"))

      # Product specific form adjustments
      @recalculateImmediately()

    # **Process Preview**
    #
    # Same as processView() but we add an interval obj to viewData to tell the
    # Mustache template to render a different part for the user. This is
    # a separate function so that it would be explicit what is being called
    # in the callbackPreview()
    #
    processPreview : (vocabTerms, view) =>
      @processViewData(vocabTerms, view)
      @viewData.preview        = @Endorse.parseIntervals(@values)
      @viewData.current_policy = @current_policy_intervals

      @trigger("loaded", this, @postProcessPreview)

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      @values.formValues.transactionType = 'Renewal'

      # Derive intervals from the form values and policy, we use
      # this in the Preview, comparing it against what comes back
      # from the server
      @current_policy_intervals = @Endorse.parseIntervals(@values)

      # These fields are verboten in Renew TR
      for f in ['comment', 'effectiveDate']
        @values.formValues[f] = '__deleteEmptyProperty'

      # Options for ChangeSet
      options =
        headers : {}

      # Success callback
      callbackFunc = @callbackSuccess

      # Previews require a different callback and an extra header.
      # The header prevents the changes from committing to the DB.
      # If preview is set to 'confirm', then ignore & commit to the DB.
      if _.has(@values.formValues, 'preview')
        if @values.formValues.preview != 'confirm'
          callbackFunc = @callbackPreview
          options.headers = _.extend(
            options.headers,
            { 'X-Commit' : false }
          )

      # Renewal requires some extra modification of the XML
      # and its quicker/dirtier to operate on the String
      # (remove EffectiveDate node)
      xml = @ChangeSet
              .getTransactionRequest(@values, @viewData)
              .replace(/\<EffectiveDate\>(.*?)\<\/EffectiveDate\>/, '')

      # Assemble the Transaction Request XML and send to server
      @ChangeSet.commitChange(
        xml,
        callbackFunc,
        @callbackError,
        options
      )

    preview : ->

    # ICS-1363 & ICS-1564
    #
    # Re-calc CoverageD immediately for CRU4-AK / SC Renewals
    #
    recalculateImmediately : ->
      policy_product = @MODULE.POLICY.getProductName()
      if policy_product == 'ofcc-ho3-ak' || policy_product == 'acic-ho3-sc'
        @triggerAllCoverageCalculations()
        @deriveCoverageACalculations()

    # Recalculate the value of the element relative to CoverageA.
    # _Note_: The value is not the percentage in the label but the
    # enumeration value which is percentage * 100
    #
    # @param `e` _Event_
    # @param `val` _Integer_
    #
    calculateCoverage : (e, val) =>
      coverage_a = parseInt(@coverage_a.val(), 10)
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

    # If CoverageA is present as well as @coverage_calculations then
    # loop through the cached calcs and do the math on CoverageA's
    # value, setting the new value back to the element that needs is.
    #
    # _Example:_
    # CoverageCalc is { CoverageD : '.2' } so get the value of
    # CoverageA and multiply it by .2, then apply that value to
    # the <input> for CoverageD.
    #
    deriveCoverageACalculations : ->
      if !_.isEmpty @coverage_calculations
        if @coverage_a.length > 0 || @coverage_a.val()?
          value_a = @coverage_a.val()
          for key, val of @coverage_calculations
            calc_val = value_a * parseFloat val
            @$el.find("input[name=#{key}]").val calc_val
