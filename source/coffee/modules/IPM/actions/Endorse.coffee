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

      console.log ['Submit', @VALUES]
      
      @VALUES.formValues.transactionType = 'Endorsement'

      # Derive intervals from the form values and policy
      current_policy = @parseIntervals(@VALUES)

      # We selectively delete certain empty values later
      if @VALUES.formValues.comment == ''
        @VALUES.formValues.comment = '__deleteEmptyProperty'

      # Options for ChangeSet
      options = {}

      # Preview require additional headers
      if _.has(@VALUES.formValues, 'preview')
        options.headers =
          'X-Commit' : false

      # xml = @CHANGE_SET.getTransactionRequest(@VALUES, @viewData)

      # Assemble the Transaction Request XML and send to server
      @CHANGE_SET.commitChange(
        @CHANGE_SET.getTransactionRequest(@VALUES, @viewData),
        @callbackSuccess,
        @callbackError,
        options
      )

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

    # **Build values for TransactionRequest**  
    # This takes the form fields and builds up a big data set to use in the TR
    # and preview. It's an almost direct port from mxAdmin and could use some
    # refactoring.
    #
    # @param `values` _Object_ @VALUES object  
    # @return _Object_  
    #
    parseIntervals : (values) ->
      form   = values.formValues
      policy = @MODULE.POLICY

      # Term from Policy XML
      term = policy.getLastTerm()

      # This is a short circuit operation to get the Interval property
      intervals = term.Intervals && term.Intervals.Interval

      # If there is only a single internal, drop into an array.
      if !_.isArray(intervals)
        intervals = [intervals]

      # Milliseconds in day, used to date calcs
      msInDay     = 24 * 60 * 60 * 1000

      # We use these for some date math later
      termStart = Date.parse term.EffectiveDate
      termEnd   = Date.parse term.ExpirationDate

      # Object we will be returning
      parsed =
        intervals : []
        term :
          startDate    : termStart
          endDate      : termEnd
          fmtStartDate : @Helpers.stripTimeFromDate(term.EffectiveDate, 'MMM D YY')
          fmtEndDate   : @Helpers.stripTimeFromDate(term.ExpirationDate, 'MMM D YY')
          days         : Math.round((termEnd - termStart) / msInDay)

      # These are the fields to get rounded
      term_fields =
        grandSubtotalNonCatUnadjusted : 'GrandSubtotalNonCatUnadjusted'
        grandSubtotalCatUnadjusted    : 'GrandSubtotalCatUnadjusted'
        grandSubtotalNonCat           : 'GrandSubtotalNonCat'
        grandSubtotalCat              : 'GrandSubtotalCat'
        grandSubtotalUnadjusted       : 'GrandSubtotalUnadjusted'
        grandSubtotal                 : 'GrandSubtotal'
        termGrandSubtotalAdjustment   : 'TermGrandSubtotalAdjustment'
        fees                          : 'TotalFees'
        grandTotal                    : 'TotalPremium'

      # Process term_fields to get clean numbers
      parsed.term = _.extend(parsed.term, @roundTermFields(term.DataItem, term_fields)) 

      # Create a fields obj for intervals by fitering out unneeded keys
      interval_field_names = [
        'grandSubtotalNonCat',
        'grandSubtotalCat',
        'grandSubtotalUnadjusted',
        'grandSubtotal',
        'fees',
        'grandTotal'
      ]
      interval_fields = _.omit(
        term_fields,
        _.difference(_.keys(term_fields), interval_field_names)
        )

      # Adjustment values used in interval processing
      adjustments =
        nonCatAdjustment : form.NonHurricanePremiumDollarAdjustmentFRC ? 0
        catAdjustment    : form.HurricanePremiumDollarAdjustmentFRC ? 0

      # Loop over intervals and parse values, storing in parse.intervals
      for interval in intervals
        startDate  = Date.parse interval.StartDate
        endDate    = Date.parse interval.EndDate

        interval_o = 
          startDate    : startDate
          endDate      : endDate
          fmtStartDate : @Helpers.stripTimeFromDate(interval.StartDate, 'MMM D YY')
          fmtEndDate   : @Helpers.stripTimeFromDate(interval.EndDate, 'MMM D YY')
          days         : Math.round((endDate - startDate) / msInDay)

        data_items = @processIntervalFields(
          interval.DataItem,
          interval_fields,
          adjustments
        )

        # Push the processed interval object onto parsed.intervals array
        parsed.intervals.push _.extend interval_o, data_items

      # Sort intervals and mark the newest one as 'isNew'
      parsed.intervals = _.sortBy(parsed.intervals, 'startDate')
      parsed.intervals[parsed.intervals.length - 1].isNew = true

      # If there is no term.grandSubTotal then copy fields from the 
      # last sorted interval into the top level of parsed. I have no
      # idea why we do this as of yet. 11/09/2012 - DN  
      if !_.has(parsed.term, 'grandSubTotal')
        interval = parsed.intervals[parsed.intervals.length - 1]
        for field, value of interval
          if !_.has(parsed, field)
            parsed[field] = value

      parsed

    # process interval fields, rounding them and then doing various calcs
    #
    # @param `terms` _Object_ Interval DataItems  
    # @param `fields` _Object_ interval fields key:val  
    # @param `adj` _Object_ adjustment values 
    # @return _Object_  combined processed values  
    #
    processIntervalFields : (terms, fields, adj) ->
      fields = @roundTermFields(terms, fields)

      processed =
        grandSubtotalNonCatUnadjusted : Math.round(
          (parseInt(fields.grandSubtotalNonCat, 10) - ~~(adj.nonCatAdjustment))
        )
        grandSubtotalCatUnadjusted : Math.round(
          (parseInt(fields.grandSubtotalCat, 10) - ~~(adj.catAdjustment))
        )

      _.extend(fields, processed, adj)

    # Find a set of term fields and return their rounded values
    #
    # @param `terms` _Object_ DataItems 
    # @param `term_fields` _Object_ term fields key:val  
    # @return _Object_  
    #
    roundTermFields : (terms, term_fields) ->
      out = {}
      for key, field of term_fields
        out[key] = Math.round(@MODULE.POLICY.getDataItem(terms, field))
      out

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

