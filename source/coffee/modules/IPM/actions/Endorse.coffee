define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class EndorseAction extends IPMActionView

    initialize : ->
      super
      @coverage_calculations     = {} # Custom calculations objects
      @transaction_request_xml   = null
      @override_validation_state = false # used to override rate validation
      @events =
        "click fieldset h3" : "toggleFieldset"

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'endorse', @processView)

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

    # **Process Preview**
    #
    # Same as processView() but we add an interval obj to viewData to tell the
    # Mustache template to render a different part for the user. This is
    # a separate function so that it would be explicit what is being called
    # in the callbackPreview()
    #
    processPreview : (vocabTerms, view) =>
      @processViewData(vocabTerms, view)
      @viewData.preview        = @parseIntervals(@values)
      @viewData.current_policy = @current_policy_intervals

      @trigger("loaded", this, @postProcessPreview)

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      @values.formValues.transactionType = 'Endorsement'

      # Derive intervals from the form values and policy, we use
      # this in the Preview, comparing it against what comes back
      # from the server
      @current_policy_intervals = @parseIntervals(@values)

      # We selectively delete certain empty values later
      if @values.formValues.comment == ''
        @values.formValues.comment = '__deleteEmptyProperty'

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

      # **ICS-1042 / ICS-429**
      # If the user ticks the override input then we need to add custom header
      # to the request. We also set state so we can remember this across
      # different requests.
      #
      if @values.formValues.id_rv_override? && @values.formValues.id_rv_override == '1'
        if _.has(options, 'headers')
          options.headers = _.extend(
            options.headers,
            { 'Override-Validation-Block' : true }
          )
        override_validation_state = true

      # Assemble the Transaction Request XML and send to server
      @ChangeSet.commitChange(
        @ChangeSet.getTransactionRequest(@values, @viewData),
        callbackFunc,
        @callbackError,
        options
      )

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
        @adjustHO3VAWaterBackupCoverage()

      # Find any custom calculations tucked away in data attrs for later
      # use in calculations
      if @coverage_a.length > 0
        if data = @coverage_a.data 'calculations'
          @coverage_calculations = (eval("(#{data})"))

      # Product specific form adjustments
      @recalculateImmediately()
      @adjustDP3NYForms()
      @adjustHO3VAWaterBackupCoverage()
      @adjustAlabamaLossTypeFields()
      @adjustAlabamaPropertyUsage()

      if @apparatchik.isProduct('wic-hwo-al') || @apparatchik.isProduct('wic-ho3-al')
        @addWICALBEhaviors()

      if @apparatchik.isProduct('fnic-ho3-la')
        @addFNICHO3LABehaviors()

      if @apparatchik.isProduct('ofcc-ho3-ca') || @apparatchik.isProduct('ofcc-ho5-ca')
        @addOFCCCABehavhiors()

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

    addOFCCCABehavhiors : ->
      rules = [
        field: "ConstructionType"
        condition: "== 100"
        target: "Cladding"
        effect: @apparatchik.showElement
      ,
        field: "ReplacementCostBuilding"
        condition: "onchange"
        target: [
          'ReplacementCostLaborMaterialsSupplies',
          'ReplacementCostDebrisRemoval',
          'ReplacementCostOverheadProfit',
          'ReplacementCostPermitsPlans'
          ]
        effect: @apparatchik.clearValue
      ,
        field: "FoundationType"
        condition: { or: ['== 150', '== 300'] }
        target: [
          "Basement",
          "FoundationBasementPercentage",
          "BasementPercentComplete"
          ]
        effect: @apparatchik.showElement
      ,
        field: "NumberOfHalfBaths"
        condition: "> 0"
        target: "HalfBathQuality"
        effect: @apparatchik.showElement
      ,
        field: "NumberOfSolarPanels"
        condition: "> 0"
        target: "SolarPanelUsage"
        effect: @apparatchik.showElement
      ,
        field: "WoodStove"
        condition: "== 100"
        target: [
          "WSApproved",
          "WSSupplementalHeatOnly",
          "WSVentedChimney",
          "WSSeparateFlue"
          ]
        effect: @apparatchik.showElement
      ,
        field: "KeroseneHeater"
        condition: "== 100"
        target: [
          "KeroseneHeaterSupplementalHeatOnly",
          "KeroseneHeaterAge"
          ]
        effect: @apparatchik.showElement
      ,
        field: "PoolType",
        sideEffects: [
          target: "PoolFence"
          condition: "== 100"
          effect: @apparatchik.showElement
        ,
          target: ["ImmovablePoolLadder", "UnlockedPoolGate"]
          condition: "== 200"
          effect: @apparatchik.showElement
        ,
          target: ["DivingBoardSlide", "PoolCovering"]
          condition: "> 1"
          effect: @apparatchik.showElement
        ]
      ,
        field: "ElectronicsSpecialLimits"
        condition: "> 1500"
        target: "ElectronicsSpecialLimitsLocation"
        effect: @apparatchik.showElement
      ,
        field: "EarthquakeCoverage"
        sideEffects: [
          condition: { or: ["== 100", "== 150"]}
          target: ["EarthquakeDeductible", "EarthquakeMasonryVeneerExclusion"]
          effect: [@apparatchik.showElement, @apparatchik.makeWritable]
        ,
          condition: "== 100"
          target: "EarthquakeDeductible"
          effect: [@apparatchik.makeReadOnly, (t) ->
              # dynamically set value of field based on parent val
              $el = @wrapField t
              $parent = @wrapField "EarthquakeCoverage"
              if ($parent.val() == '100')
                $el.val('1500')
              else
                $el.val(false)
            ]
        ]
      ,
        field: "IncidentalBusinessOccupancy"
        condition: "== 100"
        target: ["IncidentalBusinessOccupancyType",
                 "IncidentalBusinessOccupancyDescription"]
        effect: @apparatchik.showElement
      ,
        field: "Multipolicy"
        condition: "== 100"
        target: ["AutoPolicyCarier",
                 "AutoPolicyNumber"]
        effect: @apparatchik.showElement
      ]

      i = 0
      while ++i < 4
        rules.push
          field: "HomeFeatures#{i}"
          condition: "> 0"
          target: "HomeFeatures#{i}SquareFeet"
          effect: @apparatchik.showElement

      # Dynamically create sideEffects for other_structures
      other_structures_rule =
        field: "OtherStructuresIndicator"
        sideEffects: []

      j = 0
      while ++j < 4
        other_structures_rule.sideEffects.push
          target: [
              "OtherStructures#{j}Type",
              "OtherStructures#{j}Coverage",
              "OtherStructures#{j}Occupancy"
            ]
          condition: "> #{j - 1}"
          effect: @apparatchik.showElement

      # Dynamically create sideEffects for scheduled_rule
      scheduled_rule =
        field: "ScheduledPersonalPropertyIndicator"
        sideEffects : []

      k = 0
      while ++k < 11
        scheduled_rule.sideEffects.push
          target: "article_#{k}"
          condition: "> #{k - 1}"
          effect: @apparatchik.showElement

      rules.push scheduled_rule, other_structures_rule

      @apparatchik.applyEnumDynamics rules

    addFNICHO3LABehaviors : ->
      rules = [
        field: "HeatPump"
        condition: "> 100"
        target: "CentralAir"
        effect: @apparatchik.showElement
      ,
        field: "NumberOfSolarPanels"
        condition: "> 0"
        target: "SolarPanelUsage"
        effect: @apparatchik.showElement
      ,
        field: "ConstructionType"
        condition: "== 100"
        target: "Cladding"
        effect: @apparatchik.showElement
      ,
        field: "WindstormDeductibleOption"
        sideEffects: [
          target: "HurricaneDeductible"
          condition: "== 100"
          effect: @apparatchik.showElement
        ,
          target: "WindHailDeductible"
          condition: "== 200"
          effect: @apparatchik.showElement
        ]
      ]
      i = 0
      while ++i < 4
        rules.push
          field: "HomeFeatures" + i
          condition: "> 0"
          target: "HomeFeatures" + i + "SquareFeet"
          effect: @apparatchik.showElement

      @apparatchik.applyEnumDynamics rules

    # ICS-458
    # if this is a DP3 NY form and has a Coverage L & Coverage M field we
    # need to set M to 0 when L is 0, as per Andy Levens instructions.
    adjustDP3NYForms : ->
      if (@MODULE.POLICY.getProductName() != 'ofcc-dp3-ny')
        return false

      coverage_l = @$el.find('select[name=CoverageL]');
      coverage_m = @$el.find('select[name=CoverageM]');

      if coverage_m == null || coverage_l == null
        return false

      coverage_l.change ->
        if $(this).val() == '0'
          coverage_m.val '0'

        # If L > 0 && M == 0 set M to null (select..)
        if parseInt($(this).val(), 10) > 0 && coverage_m.val() == '0'
          coverage_m.val('')

      # Ensure that M stays at 0 is L is at 0
      coverage_m.change ->
        if $(this).val() != '0' && coverage_l.val() == '0'
          $(this).val '0'

    # ICS-1363 & ICS-1564
    #
    # Re-calc CoverageD immediately for CRU4-AK / SC Renewals
    #
    recalculateImmediately : ->
      policy_product = @MODULE.POLICY.getProductName()
      if policy_product == 'ofcc-ho3-ak' || policy_product == 'acic-ho3-sc'
        @triggerAllCoverageCalculations()
        @deriveCoverageACalculations()

    # ICS-1010 - Add Policy Limits option to HO3 VA form for Water Backup
    #
    # In HO3 VA policies, when "Policy Limits" is selected for the
    # WaterBackupCoverage field the value of that field should reflect
    # whatever is in Coverage A. Additionally, on form load, if Coverage A
    # is the same as whatever the value of WaterBackupCoverage is, then
    # WBC should be set to "Policy Limits" with the value of Coverage A.
    #
    adjustHO3VAWaterBackupCoverage : ->
      if @MODULE.POLICY.getProductName() != 'ofcc-ho3-va'
        return false

      $wb_coverage = @$el.find("##{@cid}_WaterBackupCoverage")

      # if Coverage_A value == WaterBackupCoverage value then set WBC value
      # to Coverage A and 'select' it.
      if parseInt($wb_coverage.val(), 10) == parseInt(@coverage_a.val(), 10)
        $wb_coverage.find('option[value="33"]').attr('value', @coverage_a.val())
        $wb_coverage.val @coverage_a.val()

      # Anytime WaterBackupCoverage changes check it against Coverage A
      # If WaterBackupCoverage is set to Policy Limits then it's val must
      # always be that of Coverage A. So when Coverage A changes, change the
      # val of WaterBackupCoverage.
      $wb_coverage.on 'change', =>
        $wb_selected = $wb_coverage.find('option:selected')
        if $wb_selected.text() == 'Policy Limits'
          $wb_selected.attr 'value', @coverage_a.val()

    # ICS-1400 - AL Forms Passing Blank Loss Type Data
    # In AL Renew forms we need to ensure that any Loss History fields that
    # have data have their LossType selects set to required.
    adjustAlabamaLossTypeFields : ->
      if (/-al/.test(@MODULE.POLICY.getProductName()) && $("##{@cid}_LossAmount1").length > 0) == false
        return false

      # Get all the LossAmount inputs
      re = RegExp "#{@cid}_LossAmount", "i"
      loss_inputs = $('input').filter (index) -> re.test($(this).attr('id'))

      # Loop through all Loss Types and if anything is entered for Amount then
      # make the LossType select required. Also attach an event listener so we
      # can remove the required attributes if the Amount is cleared back out.
      _.each loss_inputs, (input, index) =>
          $input  = $(input)
          $select = $("##{@cid}_LossType#{index+1}")

          @setLabelToRequired $select, $input.val()

          $input.on 'change', =>
            @setLabelToRequired $select, $input.val()

    # Toggle labels and required attributes for adjustAlabamaLossTypeFields
    setLabelToRequired : ($select, value) ->
      if value != ''
        @toggleRequiredStatus $select, true
      else
        @toggleRequiredStatus $select, false

    # ICS-1414 - Dynamically toggle required state of Months Unoccupied
    # based on val of Property Usage. Trying to keep this encapsulated
    # as much as possible.
    adjustAlabamaPropertyUsage : ->
      if (@MODULE.POLICY.getProductName() != 'hic-ho3-al')
        return false

      $property_usage    = @$el.find("##{@cid}_PropertyUsage");
      $months_unoccupied = @$el.find("##{@cid}_MonthsUnoccupied");

      if $property_usage.length > 0 && $months_unoccupied.length > 0
        $property_usage.on 'change', =>
          if $property_usage.val() == '100'
            @toggleRequiredStatus $months_unoccupied, false
          else
            @toggleRequiredStatus $months_unoccupied, true

        $property_usage.trigger 'change'

    # Adjust an input's required status and apply/remove class to its label
    # Used in multiple product specific adjustments
    toggleRequiredStatus : ($el, bool) ->
      $el.attr 'required', bool
      if bool
        $el.parent().find('label').addClass 'labelRequired'
      else
        $el.parent().find('label').removeClass 'labelRequired'


    # **Build Intervals values for TransactionRequest & Previews**
    # This takes the form fields and builds up a big data set to use in the TR
    # and preview. It's an almost direct port from mxAdmin and could use some
    # refactoring.
    #
    # @param `values` _Object_ @values object
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
        parsed.intervals.push(_.extend(interval_o, data_items))

      # Sort intervals and mark the newest one as 'isNew' - this is
      # used in the Preview tables
      parsed.intervals = _.sortBy(parsed.intervals, 'startDate')
      parsed.intervals[parsed.intervals.length - 1].isNew = true

      # If there is no term.grandSubTotal then copy fields from the
      # last sorted interval into the top level of parsed. I have no
      # idea why we do this as of yet. 11/09/2012 - DN
      # if !_.has(parsed.term, 'grandSubTotal')
      #   interval = parsed.intervals[parsed.intervals.length - 1]
      #   for field, value of interval
      #     if !_.has(parsed, field)
      #       parsed[field] = value

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

    preview : ->
