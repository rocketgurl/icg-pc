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

      @MILLISECONDS_PER_DAY = 24 * 60 * 60 * 1000
      @MONEYFIELDS = ['GrandSubtotalNonCatUnadjusted',
                      'GrandSubtotalCatUnadjusted',
                      'GrandSubtotalNonCat',
                      'GrandSubtotalCat',
                      'GrandSubtotal',
                      'TotalFees',
                      'TotalPremium']

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

      # Used in processPreview
      @previousTerms = @getTermsForPreview()

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

      # Product specific form adjustments
      @addOFCCHO3AKBehaviors() if @apparatchik.isProduct('ofcc-ho3-ak')

      if @apparatchik.isProduct('wic-ho3-nj') || @apparatchik.isProduct('ofcc-ho3-nj')
        @addWICALBEhaviors()

    # **Process Preview**
    #
    # Same as processView() but we add an interval obj to viewData to tell the
    # Mustache template to render a different part for the user. This is
    # a separate function so that it would be explicit what is being called
    # in the callbackPreview()
    #
    processPreview : (vocabTerms, view) =>
      # Do some initial gathering using Endorse methods
      @processViewData(vocabTerms, view)
      @viewData.preview        = @Endorse.parseIntervals(@values)
      @viewData.current_policy = @current_policy_intervals

      @viewData.proposedTerm = @getTermsForPreview true
      @viewData.previousTerms = @previousTerms

      # If a premium override has been entered we need to display a message
      if !_.isEmpty(@viewData.GrandSubtotalOverride)
        @viewData.premiumOverride = true
        @viewData.msg = true
        @viewData.msgType = 'warning'
        @viewData.msgHeading = 'A premium override has ben applied'
        @viewData.msgText = 'Values affected by the override are highlighted below.'

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


    # We need to return a data set made of Proposed Term and Previous
    # Term. We use the Terms of the policy and abstract out the items
    # that we need, returning an array of the custom object(s)
    #
    # @param _Boolean_ last_term  if true then just use lastTerm()
    # @return _Array_
    #
    getTermsForPreview : (last_term) ->

      terms = if last_term then [@MODULE.POLICY.getLastTerm()] else @MODULE.POLICY.getTerms()
      vocab_terms = @tpl_cache.Renew.model || {}

      _.map terms, (term) =>
        current = @MODULE.POLICY.getTermDataItemValues(vocab_terms)

        # Remove any false values from object
        current_term = _.object(_.keys(current), _.map(_.values(current), (i) -> i || ""))

        start_date = Date.parse term.EffectiveDate
        end_date = Date.parse term.ExpirationDate

        current_term.startDate = @Helpers.stripTimeFromDate term.EffectiveDate, 'MM DD YYYY'
        current_term.endDate = @Helpers.stripTimeFromDate term.ExpirationDate, 'MM DD YYYY'

        current_term.days = Math.round (end_date - start_date) / @MILLISECONDS_PER_DAY

        # There was a situation (in the murky past) in which FRC values
        # were coming up null, so we needed to ensure a zero value
        catAdjust = current_term.HurricanePremiumDollarAdjustmentFRC || 0
        nonCatAdjust = current_term.NonHurricanePremiumDollarAdjustmentFRC || 0

        current_term.GrandSubtotalNonCatUnadjusted =
          parseInt(current_term.GrandSubtotalNonCat, 10) - parseInt(nonCatAdjust, 10)

        current_term.GrandSubtotalCatUnadjusted =
          parseInt(current_term.GrandSubtotalCat, 10) - parseInt(catAdjust, 10)

        # format $$ fields
        @formatMoneyFields current_term, @MONEYFIELDS

    # Loop through whitelisted fields and format for display as $$
    formatMoneyFields : (term, whitelist) ->
      _ret = _.clone term
      for w in whitelist
        _ret[w] = @Helpers.formatMoney parseInt(_ret[w], 10)
      _ret

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

    ###
    # Apparatchik!
    # ============
    # These are the "business logic" rules (think COBOL) which govern
    # how fields behave based on certain conditions. Go look at the
    # comments in /source/js/lib/Apparatchik.js to get a feel for how
    # they work - it's real easy man.
    #
    # NOTE: These will start to get lengthy, you may want to move
    # them into external files and pull in via RequireJS.
    ###

    addWICALBEhaviors : ->
      rules = [
        field: "WindstormDeductibleOption"
        sideEffects: [
          target: "HurricaneDeductible"
          condition: "== 100"
          effect: [@apparatchik.showElement, @apparatchik.makeRequired]
        ,
          target: "WindHailDeductible"
          condition: "== 200"
          effect: [@apparatchik.showElement, @apparatchik.makeRequired]
        ]
      ]

      @apparatchik.applyEnumDynamics rules

    addOFCCHO3AKBehaviors : ->
      # ICS-2557 Set InsuranceScore to ReadOnly when PolicyTerm < 2
      policy_term = @MODULE.POLICY.getPolicyTerm()
      $insurance_score = @$el.find('input[name=InsuranceScore]')
      $insurance_score.prop('readonly', policy_term < 2)

