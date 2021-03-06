define [
  'BaseView',
  'Messenger',
  'modules/IPM/IPMChangeSet',
  'modules/IPM/IPMFormValidation',
  'Apparatchik'
], (BaseView, Messenger, IPMChangeSet, IPMFormValidation, Apparatchik) ->

  ###
    Still relevant?
    ACTIONVIEWS TODO:
      Write off charges
      Issue (automatic)
      Issue (manual)
      Renew
      Update mortgage
      Change additional interest
      Edit term data
  ###

  # IPMActionView
  # ----
  # IPM sub views (action views) inherit from this base view
  #
  # * The IPMView loads IPMActionView (this) and attaches a 'loaded' listener
  #   to it. The 'ready' event is then triggered. This usually tells the
  #   inherited ActionView to go and get its templates (fetchTemplates())
  #
  # * fetchTemplates() GETs model.json and view.html and then calls callback,
  #   which in many cases is processView()
  #
  # * processView() handles the loading of data into the template, any
  #   transforms on the data, etc. When it's done, the 'loaded' event is
  #   triggered, which tells IPMActionView's listener to fire render().
  #   When loaded is triggered, a callback is passed along which tells
  #   render() what to do when it's done slotting the view into the DOM.
  #   We do this because we need to change the post-render callback depending
  #   on what we just rendered. Sometimes we are rendering a preview, which
  #   has different post-rendering needs.
  #
  # * postProcessView() / postProcessPreview() is called after the 'loaded'
  #   event. We need to do this after the DOM has been updated. These functions
  #   operate on the form's DOM to attach listeners
  #
  # * Submit - the submit function is wrapped in validate() - which checks
  #   the form to ensure all required fields are filled. See IPMFormValidation
  #   for more information on how validation goes down. If the form validates,
  #   submit() preps the values for sending, keeping
  #   versions and preview data up to date.
  #
  #   Each action which inherits from IPMActionView adds its own custom submit
  #   processing into the mix. Finally a ChangeSet or Transaction Request is
  #   sent to server. Callbacks are passed into ChangeSet.commitChange()
  #   to handle success/fail
  #
  #
  class IPMActionView extends BaseView

    # A list of sections that may need additional updates in certain cases.
    # There will need to be a corresponding method to determine what specific changes
    # should be mapped from what field for another e.g. `@getPayeeChanges()`
    additionalFieldSections : [
      'Payee'
      'Payor'
    ]

    tagName : 'div'

    events : {}

    # !!! Your Action View should define the following methods:
    ready          : ->
    preview        : ->
    processView    : ->
    processPreview : ->

    initialize : (options) ->
      @PARENT_VIEW    = options.PARENT_VIEW ? {}
      @MODULE         = options.MODULE ? {}
      @ChangeSet      = new IPMChangeSet(@MODULE.POLICY, @PARENT_VIEW.view_state, @MODULE.USER)
      @FormValidation = new IPMFormValidation()

      @values    = {} # Form values
      @tpl_cache = {} # Template Cache
      @errors    = {} # Manage error states from server

      @options = null

      @on('ready', @ready, this)

      # We need to validate form submits
      if _.isFunction(@submit)
        @submit = _.wrap @submit, (submit) =>
          args = _.toArray arguments
          if @validate()
            submit(args[1])

      # Apparatchik is our Rules Cop for enforcing behavior sets in
      # forms. It is actually documented in js/lib/Apparatchik.js
      @apparatchik = new Apparatchik(@cid, @MODULE.POLICY, @MODULE.VIEW, @$el)

    # **fetchTemplates** grab the model.json and view.html for processing
    #
    # @param `policy` _Object_ PolicyModel
    # @param `action` _String_ Name of this action
    # @param `callback` _Function_ function to call on AJAX success
    #
    fetchTemplates : (policy, action, callback, nocache = false) ->
      if !policy? || !action?
        return false

      # Dovetail policies are scoped only to BoR and don't have most forms
      product_name = if policy.isDovetail() then 'dovetail' else policy.get('productName')

      path  = "/js/#{@MODULE.CONFIG.PRODUCTS_PATH}#{product_name}/forms/#{_.slugify(action)}"
      
      # Stash the files in the cache on first load
      if _.isNull(@tpl_cache) || !_.has(@tpl_cache, action) || nocache
        model = $.getJSON("#{path}/model.json")
                 .pipe (resp) -> return resp
        view  = $.get("#{path}/view.html", null, null, "text")
                 .pipe (resp) -> return resp
        $.when(model, view).then(callback, @PARENT_VIEW.actionError)
      else
        callback(@tpl_cache[action].model, @tpl_cache[action].view)

    # **Return to home page of IPM**
    #
    # @param `e` _Event_
    #
    goHome : (e) ->
      e.preventDefault()
      @PARENT_VIEW.route 'Home'

    # Open/close fieldsets
    #
    # @param `e` _Event_
    #
    toggleFieldset : (e) ->
      e.preventDefault()
      h3        = $(e.currentTarget)
      a         = h3.find('a')
      container = h3.parent().find('.collapsibleFieldContainer')

      # Toggle visibility states
      if container.css('display') == 'none'
        container.css('display', 'block')
      else
        container.css('display', 'none')

      # Swap anchor text
      a_html = a.html()
      a.html(a.data('altText')).data('altText', a_html)


    # **Post process the rendered view**
    #
    # This is where we add things like required labels and such after the
    # ActionView has been rendered. You can add to this through inheritance
    # using `super` in your actions
    #
    postProcessView : ->
      # Initial cancle button goes back to home screen
      @$el.find('.form_actions a').on 'click', (e) =>
        @goHome(e)

      # Set all Enum selects to their default values
      $('select[data-value]').val ->
        $(this).attr('data-value')

      # Attach datepickers where appropriate
      $dp = @$el.find('.datepicker')

      # ICS-2408: Insured1BirthDate format mm/dd/yy. Note that ui datepicker format
      # differs from moment.js as seen in IPMChangeSet, for example.
      date_options =
        dateFormat : if $dp.attr('name') is 'Insured1BirthDate' then 'mm/dd/yy' else 'yy-mm-dd'

      if $.datepicker
        $dp.datepicker(date_options)

      # Attach event listener to preview button
      @$el.find('form input[type=submit]').on(
          'click',
          (e) =>
            e.preventDefault()
            @submit e
        )

    # **Post process the preview of the form**
    postProcessPreview : ->
      delete @viewData.preview

      # Swap out click event on cancel button to just reset to beginning state
      @$el.find('.form_actions a').on 'click', (e) =>
        e.preventDefault()
        @rollbackPolicyModel()
        @processView(
          @tpl_cache[@PARENT_VIEW.view_state].model,
          @tpl_cache[@PARENT_VIEW.view_state].view
        )

      # .data_tables in the preview require additional hooks and processing
      if @$el.find('.data_table').length > 0
        @processPreviewForm(@$el.find('.data_table'))

    # **Get the form values**
    #
    # @param `form` _HTML Form Element_
    # @return _Object_ key:val object of form values
    #
    getFormValues : (form) ->
      formValues = {}
      for item in form.serializeArray()
        formValues[item.name] = item.value
      formValues

    # **Which form values changed?**
    #
    # @param `form` _HTML Form Element_
    # @return _Object_ key:val object of changed form values
    #
    getChangedValues : (form) ->
      changed = []
      form.find(':input').each (i, element) ->
        el     = $(element)
        name   = el.attr 'name'
        oldval = el.data 'value'
        newval = el.val()

        # Check on data-value of <select> element
        #
        # _Note:_ We are explicity using '!=' instead of CoffeeScript's
        # automatic conversion to '!==' because the values from the form
        # are all different types and we need loose comparisons to prevent
        # writing a shit ton of explicit detections & coercion code.
        # This could cause an issue going forward, hence the note. - DN
        #
        if el.is 'select'
          unless oldval == '' && newval == '0'
            changed.push(name) if newval? && `el.data('value') != newval`

        # Check on <textarea> fields.
        else if el.is 'textarea'
          if newval.trim() != ''
            changed.push name
          if newval.trim() == '' && el.data('hadValue')
            changed.push name

        else
          if newval != element.getAttribute('value')
            changed.push name

      changed

    # **Mapping changed values to additional fields**
    #
    # See ICS-2033 & ICS-2034
    # When changes are made to a particular set of fields, defined as keys in
    # the `keyMap` parameter, automatically update the corresponding values.
    # Returns an object of mapped values
    #
    # @param `keyMap`   _Object_ maps keys to corresponding values
    # @param `combined` _Object_ [optional] certain fields combine the values of other fields
    #
    mapAdditionalFields : (keyMap, combined) ->
      changes  = @values.changedValues
      formVals = @values.formValues
      mappedItems = {}

      _.each changes, (change) ->
        if (mappedKey = keyMap[change]) && formVals[change]?
          mappedItems[mappedKey] = formVals[change]

      _.each combined, (list, key) ->
        if (_.intersection list, changes).length
          concatVal = ''
          _.each list, (item) ->
            concatVal += "#{formVals[item]} " if formVals[item]

          if concatVal.length
            mappedItems[key] = concatVal.trim()

      mappedItems unless _.isEmpty mappedItems

    # For each <section> listed in `@additionalFieldSections`, there should be
    # a corresponding method called @get<section>Changes. e.g. @getPayeeChanges()
    getAdditionalFieldChanges : ->
      changes = {}
      _.each @additionalFieldSections, (section) =>
        sectionChanges = @["get#{section}Changes"]()
        unless _.isEmpty sectionChanges
          changes[section] = sectionChanges
      changes

    # **Generate a collection of partial templates to be rolled into a PCS**
    #
    # @param `changes` _Object_ changes to be rendered
    #
    getAdditionalFieldPartial : (changeSet, type) ->
      changedItems =
        dataItems : _.map changeSet, (val, key) -> { name : key, value : val }
      template = @ChangeSet[_.underscored("change#{type}")] or ''
      partial =
        body : @Mustache.render template, changedItems

    # **Commit changes that have been mapped to a separate set of dataItems**
    #
    # Unfortunately, we have to get tricky here.
    # A policy changeset will not allow us more than 1 kind of change / event at a time.
    # And if we attempt to post 2 changesets in parallel, we get a 409 conflict.
    #
    # @param `changes`   _Object_ collection of changes to be committed
    #
    commitAdditionalFieldChanges : (changes) ->
      # `_.some` in underscore.js will evaluate to true if there are any items in the
      # collection and will execute the predicate function on the first item returned.

      # While there are still items in the collection, we pop off the current item and
      # pass the now smaller collection to the success callback, which then recursively
      # re-invokes `commitAdditionalFieldChanges` until all the changes are committed and the
      # collection is empty.
      _.some changes, (change, type) =>
        partial = @getAdditionalFieldPartial change, type
        changedFields = _.keys change

        # Get necessary info for Policy ChangeSet
        context =
          id      : @MODULE.POLICY.get 'insightId'
          user    : @MODULE.USER.get 'email'
          version : @MODULE.POLICY.getValueByPath 'Management Version'
          comment : 'posted by Policy Central IPM Module'

        # delete the current changeSet
        delete changes[type]
        
        # Assemble the ChangeSet XML and send to server
        @ChangeSet.commitChange(
          @Mustache.render(@ChangeSet.policyChangeSetSkeleton, context, partial)
          @callbackAdditionalFieldSuccess(changedFields, changes)
          @callbackError
          )

        return true

    # Constructs a success message and returns the callback function in a closure
    callbackAdditionalFieldSuccess : (changedFields, changes) =>
      msg = """
        <p>Updates to fields:</p>
        <ul><li>#{changedFields.join('</li><li>')}</li></ul>
        <p>Completed successfully</p>
      """

      (data, status, jqXHR) =>
        @PARENT_VIEW.displayMessage 'success', msg, 6000

        # Refresh the PolicyModel with the returned policy
        @resetPolicyModel data, jqXHR, true

        # commit additional field changes if the changes collection is not empty
        @commitAdditionalFieldChanges changes

    # Map any changes to primary insured name or mailing address
    # to payee fields and submit additional transaction request.
    # This should only happen when in the 'ChangeCustomer' action
    getPayeeChanges : ->
      if @PARENT_VIEW.view_state is 'ChangeCustomer'
        payeeMap =
          'InsuredMailingAddressLine1' : 'OpPayeeDisbursementAddressLine1'
          'InsuredMailingAddressLine2' : 'OpPayeeDisbursementAddressLine2'
          'InsuredMailingAddressCity'  : 'OpPayeeDisbursementCity'
          'InsuredMailingAddressState' : 'OpPayeeDisbursementState'
          'InsuredMailingAddressZip'   : 'OpPayeeDisbursementZip'

        # PayeeDisbursement is the Insured's full name
        combined =
          'OpPayeeDisbursement' : ['InsuredFirstName', 'InsuredLastName']

        @mapAdditionalFields payeeMap, combined

    # Logic to follow:
    # - If paymentplantype is 'invoice',
    # -- use first mortgagee information as the payor information
    # -- and change Payor field to '100'
    # - If paymentplantype is not 'invoice',
    # -- use the primary insured mailing address and first named insured as the payor information
    # -- and change Payor field to '200'
    getPayorChanges : ->
      payorVocab = @getPayorVocab @values.formValues.paymentPlanType
      combined = {}

      if payorVocab is 100
        payorMap =
          'MortgageeNumber1'       : 'OpPayorName'
          'Mortgagee1AddressLine1' : 'OpPayorAddressLine1'
          'Mortgagee1AddressLine2' : 'OpPayorAddressLine2'
          'Mortgagee1AddressCity'  : 'OpPayorCity'
          'Mortgagee1AddressState' : 'OpPayorState'
          'Mortgagee1AddressZip'   : 'OpPayorZip'
          'payor'                  : 'OpPayor'
      else
        payorMap =
          'InsuredMailingAddressLine1' : 'OpPayorAddressLine1'
          'InsuredMailingAddressLine2' : 'OpPayorAddressLine2'
          'InsuredMailingAddressCity'  : 'OpPayorCity'
          'InsuredMailingAddressState' : 'OpPayorState'
          'InsuredMailingAddressZip'   : 'OpPayorZip'
          'payor'                      : 'OpPayor'

        combined.OpPayorName = ['InsuredFirstName', 'InsuredLastName']

      @mapAdditionalFields payorMap, combined

    # Get Payor vocab code based on payment plan type
    getPayorVocab : (paymentPlanType) ->
      unless paymentPlanType
        paymentPlanType = @MODULE.POLICY.getPaymentPlanType()

      if paymentPlanType is 'invoice'
        100
      else
        200

    # Use the vocabTerms (model.json) to derive the policy data the form needs
    # specific to this ActionView and cache it.
    #
    # @param `vocabTerms` _Object_ model.json
    # @param `view` _HTML Template_
    # @param `nocache` _Boolean_ on true do not store data in cache
    # @param `term` _Object_ optional term to override the default Term in getTermDataItemValues
    # @return _Array_ [viewData, view]
    #
    processViewData : (vocabTerms, view, nocache, term = null) ->
      if !nocache?
        @tpl_cache[@PARENT_VIEW.view_state] =
          model : vocabTerms
          view  : view

      viewData = {}

      if vocabTerms?
        viewData = @MODULE.POLICY.getTermDataItemValues(vocabTerms, term)
        viewData = @MODULE.POLICY.getEnumerations(viewData, vocabTerms)

      viewData = _.extend(
        viewData,
        @MODULE.POLICY.getPolicyOverview(),
        {
          policyOverview : true
          policyId : @MODULE.POLICY.get_pxServerIndex()
        }
      )

      # We need to add the CID to the view data to namespace all the
      # form ids or everything explodes and sinks into the ocean.
      viewData.guid = @cid

      # Filter false values out
      for key, val of viewData
        if val == false then viewData[key] = "" else viewData[key] = val

      @viewData = viewData
      @view     = view

      [viewData, view]

    # **Handle calculations in preview fields**
    # Some products can manipulate fields in the preview phase. We need to
    # attach some behaviors to those fields and then run the numbers. We also
    # need to attach some flags to the form so the submit handler will know
    # what to do on a "re-submit".
    #
    # @param `table` _HTML Element_ jQuery wrapped table
    #
    processPreviewForm : (table) ->
      # Disable button until something changes
      update_button = @$el.find('#updatePreview')
      update_button.attr('disabled', true)

      # if an Adjustment value is changed for either category then we need
      # to re-caclculate that category's Adjusted value
      table.find('tr.calc_row input').each (i, val) ->
        $input        = $(this) # cache the jQuery wrapped element
        parentRow     = $input.closest 'tr.calc_row'
        unadjustedVal = parseInt($input.parent().prev().text(), 10) || 0
        adjustedElem  = $input.parent().next()
        subTotalElem  = parentRow.find 'td.subtotal'

        # As typing happens update this category's Adjustment value
        # http://stackoverflow.com/questions/5971645/what-is-the-double-tilde-operator-in-javascript#5971668
        $input.on 'keyup', (e) ->
          adjustmentVal = ~~(this.value)
          subTotalView  = ~~(subTotalElem.text())

          # Update the adjustment value
          adjustedElem.text(unadjustedVal + adjustmentVal)

          # Re-calc subtotal
          subTotalElem.trigger 'adjust'

          # Re-enable button
          update_button.attr('disabled', false)

      # Each time either category's adjustment values are changes, we also need
      # to update Premium Before Fees (grandSubtotal)
      table.find('tr.calc_row').each (i, val) ->
        $tr            = $(this) # cache the jQuery wrapped element
        calculatedVals = $tr.find 'td.calculated_value'
        subtotalElem   = $tr.find 'td.subtotal'
        feesElem       = $tr.find 'td.fees'
        totalElem      = $tr.find 'td.total'
        originSubtotal = parseInt(subtotalElem.text(), 10) || 0
        fees           = parseInt(feesElem.text(), 10) || 0
        originTotal    = parseInt(totalElem.text(), 10) || 0

        subtotalElem.on 'adjust', ->
          newSubtotal = 0
          newTotal = 0

          # Subtotal is sum of calculated values
          calculatedVals.each (i, val) ->
            amt         = parseInt($(this).text(), 10) || 0
            newSubtotal = newSubtotal + amt

          # Subtotal is Cat plus NonCat Adjusted values. 1000 format.
          subtotalElem.text(newSubtotal)

          # total is subtotal plus fees. 1000 format.
          totalElem.text(newSubtotal + fees)


      # Create click handler for updatePreview button and inject hidden form
      # field into the DOM.
      #
      # Maintain state within the table itself. I think this is to prevent
      # multiple submits of the new data
      #
      if !table.data('initialized')
        table.data('initialized', true)
        update_button.on 'click', =>
          @$el.find('form')
            .append('<input type="hidden" id="id_preview" name="preview" value="re-preview">')
          @submit()

      # Attach event listener to confirm button, changing the value of the
      # hidden preview field to 'confirm'
      @$el.find('form input[type=submit]').on(
          'click',
          (e) =>
            @$el.find('form input[name=preview]').attr('value', 'confirm')
            @submit e
        )


    # **Success handling from ChangeSet**
    #
    # @param `data` _XML_ Policy XML
    # @param `status` _String_ Status of callback
    # @param `jqXHR` _Object_ XHR object
    #
    callbackSuccess : (data, status, jqXHR) =>
      # Assemble any changed payee/payor values before Policy Refresh
      additionalFieldChanges = @getAdditionalFieldChanges()
   
      #if the ChangeSet/Transaction is successful, we want to send the Notes
      #as an additional post asyncronously and then go ahead and handle the success
      #messaging for the action
      @postAdditionalNotes @MODULE.POLICY
      
      #handle the message success      
      msg_text = if @PARENT_VIEW.success_msg then @PARENT_VIEW.success_msg else @PARENT_VIEW.view_state
      msg = "#{msg_text} completed successfully"

      @PARENT_VIEW.displayMessage('success', msg, 3000).remove_loader()

      # Force reset values to prevent caching of Policy versions
      @values = {}

      # Load returned policy into PolicyModel
      @resetPolicyModel(data, jqXHR, true)

      @PARENT_VIEW.route 'Home'

      # Post Payee/Payor changes in the background
      unless _.isEmpty additionalFieldChanges
        @commitAdditionalFieldChanges additionalFieldChanges


    # **Error handling from ChangeSet**
    #
    # @param `jqXHR` _Object_ XHR object
    # @param `status` _String_ Status of callback
    # @param `error` _String_ Error
    #
    callbackError : (requestPayload) =>

      # Returns a closure so we can catch the request Payload
      # for better error handling
      (jqXHR, status, error) =>
        if !jqXHR
          @PARENT_VIEW.displayError(
            'warning',
            'Fatal: Error received with no response from server'
          ).remove_loader()

          return false

        # Rate validation errors get special treatment
        if @PARENT_VIEW.view_state == 'Endorse' && \
          jqXHR.getResponseHeader('Rate-Validation-Failed')
            return @displayRateValidationError()

        if jqXHR.responseText? and jqXHR.status isnt 0
          regex = /\[(.*?)\]/g
          json  = regex.exec(jqXHR.responseText)

          # If this is an endorse action and the response is JSON then there is
          # a high chance this could be a rate validation error.
          if json? && @PARENT_VIEW.view_state == 'Endorse'
            @errors = @errorParseJSON(jqXHR, json)
          else
            @errors = @errorParseHTML(jqXHR)
        else if jqXHR.status is 0
          @errors =
            title : "Timeout Error (#{jqXHR.status})"
            desc  : "The server request has timed out with a status of (#{jqXHR.status})"
        else
          @errors =
            title : "#{status.toUpperCase()} (#{jqXHR.status})"
            desc  : "XMLHTTPRequest status: #{error} (#{jqXHR.status})"

        @displayError 'warning', @errors

        # Log a hopefully useful ajax error for TrackJS
        info = ""
        try
          info = """
IPM Action XMLHTTPResponse Error (#{jqXHR.status}) #{jqXHR.statusText}
IPMAction: #{@ChangeSet.ACTION}
ErrorName: #{@errors.title}
ErrorMessage: #{@errors.desc}
RequestPayload: #{requestPayload}
ResponseHeaders: #{jqXHR.getAllResponseHeaders()}
          """
          throw new Error "IPM Action Error"
        catch ex
          console.info info
    
    # **Notes field handling, post a notes ChangeSet**
    #
    # @param `policy` _Object_ PolicyModel
    #
    postAdditionalNotes : (policy) =>
    
      #Get the Notes field value, if it exists
      #currentForm was added to ensure the correct addNotes textarea was used, as that field 
      #is included on multiple form elements
      notes = @currentForm.find('textarea[name=addNotes]').val()
      notes = $.trim(notes)
      delete @currentForm
      
      #if user does not add notes, skip this step entirely  
      if notes? and notes isnt ''
        username = @MODULE.USER.get 'username'
          
        tpl = """
<PolicyChangeSet schemaVersion="2.1" username="{{username}}" description="Adding a note">
  <Note>
    <Content><![CDATA[{{{notes}}}]]></Content>
  </Note>
</PolicyChangeSet>
        """

        xml = @Mustache.render tpl, {notes: notes, username: username}
        xmldoc  = $.parseXML(xml) #Parse xml w/jQuery
        payload_schema = "schema=#{@ChangeSet.getPayloadType(xmldoc)}.#{@ChangeSet.getSchemaVersion(xmldoc)}" 
      
        # Assemble the AJAX params
        options =
          url         :  policy.url()
          type        : 'POST'
          dataType    : 'xml'
          contentType : "application/xml; #{payload_schema}"
          context     : @
          data        : xml
          headers     :
              'Authorization' : "Basic #{policy.get('digest')}"
              'Accept'        : 'application/vnd.ics360.insurancepolicy.2.8+xml'
              'X-Commit'      : true

        # Post
        post = $.ajax(options)
        $.when(post).then(@callbackNoteSuccess, @callbackNoteError(xml))


    # **Success handling from ChangeSet (Note Save)**
    #
    # @param `data` _XML_ Policy XML
    # @param `status` _String_ Status of callback
    # @param `jqXHR` _Object_ XHR object
    #
    callbackNoteSuccess : (data, status, jqXHR) =>
        
        #A successful note save will occur silently
        return
        
       
    # **Error handling from ChangeSet (Note Save)**
    #
    # @param `jqXHR` _Object_ XHR object
    # @param `status` _String_ Status of callback
    # @param `error` _String_ Error
    #
    callbackNoteError : (requestPayload) =>

      (jqXHR, status, error) =>
        # On a note save, we want to post the error to the screen as a
        # secondary error warning if it fails
        
        # If we don't get an XHR response, then something very bad has
        # happened indeed.
        if !jqXHR
          @PARENT_VIEW.displayError(
            'warning',
            'Fatal: Error received with no response from server'
          ).remove_loader()

          return false

        @errors = @errorParseHTML(jqXHR)

        @displayError 'warning', @errors

        # Log a hopefully useful ajax error for TrackJS
        info = ""
        try
          info = """
IPM Add Note XMLHTTPResponse Error (#{jqXHR.status}) #{jqXHR.statusText}
ErrorName: #{@errors.title}
ErrorMessage: #{@errors.desc}
RequestPayload: #{requestPayload}
ResponseHeaders: #{jqXHR.getAllResponseHeaders()}
          """
          throw new Error "IPM Action Error"
        catch ex
          console.info info
      
        

    # **Preview Callback**
    # If a policy comes back to for Preview we need to do a little processing
    # before we display it to the user. This is called by ActionView as part
    # of the IPMChangeSet.commitChange() callback.
    #
    # * First, inject the new policy XML into the model and setModelState()
    # * Second, pass the view and model.js to ActionView.processPreview()
    #
    # @param `data` _XML_ PolicyModel
    # @param `status` _String_ Status of callback
    # @param `jqXHR` _Object_ XHR object
    #
    callbackPreview : (data, status, jqXHR) =>
      @resetPolicyModel(data, jqXHR)

      if !_.has(@tpl_cache, @PARENT_VIEW.view_state) || !_.has(@tpl_cache[@PARENT_VIEW.view_state], 'model')
        @PARENT_VIEW.route 'Home'
        @displayError 'warning', 'Lost track of sub-view, try again.'
        return

      @processPreview(
        @tpl_cache[@PARENT_VIEW.view_state].model,
        @tpl_cache[@PARENT_VIEW.view_state].view
      )
      @PARENT_VIEW.remove_loader()

    # **Load new XML into PolicyModel**
    #
    # Inject the new policy XML into the model and setModelState()
    #
    # @param `data` _XML_ PolicyModel
    # @param `jqXHR` _Object_ XHR object
    # @param `hard` _Bool_ true will remove any previous model attrs
    # @return _Object_ PolicyModel
    #
    resetPolicyModel : (data, jqXHR, hard = false) ->
      # Parse XML into something useful
      new_attributes = @MODULE.POLICY.parse(data, jqXHR)

      if hard
        # Swap out Policy XML with new XML, Do not save previous versions
        @MODULE.POLICY.unset('prev_document')
      else
        # Swap out Policy XML with new XML, saving the old one
        new_attributes.prev_document =
          document : @MODULE.POLICY.get('document')
          json     : @MODULE.POLICY.get('json')

      # Model.set() chokes on something in the object, so we just
      # jam the values into attributes directly. So sorry Mr. Ashkenas.
      for key, val of new_attributes
        @MODULE.POLICY.attributes[key] = val

      # Tell the model to set its state based on the new XML values
      @MODULE.POLICY.trigger 'change', @MODULE.POLICY

      @MODULE.POLICY

    # Return PolicyModel to its previous state if it has one
    #
    # @return _Object_ PolicyModel
    #
    rollbackPolicyModel : ->
      prev = @MODULE.POLICY.get('prev_document')
      if prev?
        for key, val of prev
          @MODULE.POLICY.attributes[key] = val

          # Tell the model to set its state based on the new XML values
          @MODULE.POLICY.trigger 'change', @MODULE.POLICY

      @MODULE.POLICY


    # **Render ActionView into DOM**
    #
    # Render template with Mustache.js
    #
    # @param `viewData` _Object_ model.json
    # @param `view` _String_ HTML template
    #
    render : (viewData, view) ->
      viewData = viewData || @viewData
      view     = view || @view
      @$el.html(@MODULE.VIEW.Mustache.render(view, viewData))

    # Validate form with IPMFormValidation and display any errors
    #
    # @return _Boolean_
    #
    validate : ->
      # Convert all required fields into a validators object
      required_fields = \
        @FormValidation.processRequiredFields(
          @$el.find('input[required], select[required]').get()
        )

      # Mutate validators to contain the required_fields rules
      @FormValidation.validators = \
        @FormValidation.mergeValidators(
          required_fields,
          @FormValidation.validators,
          @$el,
          @cid
        )

      fields = for field, rules of @FormValidation.validators
        $("##{@cid}_#{field}")

      errors = @FormValidation.validateFields(fields)

      if _.isEmpty errors
        true
      else
        # Pop open fieldsets with invalid inputs
        @displayInvalidFields(errors)

        @PARENT_VIEW.displayMessage(
          'warning',
          @FormValidation.displayErrorMsg(errors)
        )
        false

    # **Submit form** - set the form values on the ActionView for
    # use in inherited ActionViews. Only do this if there is an actual form,
    # otherwise we're probably in a preview state and need to hold onto the
    # original form values.
    #
    # _Note:_ This method should be extended in child views
    # _Note:_ This is wrapped by @validate() during initialize!
    #
    # @param `e` _Event_ Submit event (Optional)
    #
    submit : (e) =>
      if e?
        e.preventDefault()

      @PARENT_VIEW.insert_loader('Processing policy') # Add loader

      form = @$el.find('form')
      
      # currentForm was added to support the postAdditionNotes function 
      @currentForm = form
      
      if form.length > 0

        @values.formValues    = @getFormValues form
        @values.changedValues = @getChangedValues form

        # If we have previous values then cons them onto the new values
        if _.has(@values, 'previousValues')
          @values.formValues = _.extend(
            @values.previousValues.formValues,
            @values.formValues
          )
          @values.changedValues = \
            _.uniq @values.changedValues.concat(@values.previousValues.changedValues)

        # In previews we need to keep the previous form states as we re-calc
        # and re-submit the TransactionRequests multiple times, making changes.
        # We purposefully delete the preview field in our saved set as we don't
        # want it overriding the combined value later (we use it to trigger
        # things.) We use _.clone because we want the data, not a ref to the obj
        #
        if _.has(@values.formValues, 'preview') && @values.formValues.preview != 'confirm'
          @values.previousValues =
            formValues    : _.clone @values.formValues
            changedValues : _.clone @values.changedValues
          delete @values.previousValues.formValues.preview # we don't want this

    # **Pop open the fieldset for any invalid input**
    #
    # @param `errors` _Object_ collection of invalid inputs
    # @return _void_
    #
    displayInvalidFields : (errors) ->
      for error in errors
        # bootstrap collapse
        $panelCollapse = error.element.parents '.panel-collapse'
        if $panelCollapse.is ':hidden'
          $panelCollapse.collapse 'show'

        # old method
        $container = error.element.parents('.collapsibleFieldContainer')
        $fieldset = $container.parent()
        if $container.css('display') == 'none'
          $fieldset.find('h3').trigger 'click'

    # **Parse error message from HTML response**
    #
    # @param `jqXHR` _Object_ XHR object
    # @return _Object_ Error object
    #
    errorParseHTML : (jqXHR) ->
      # Assemble error message
      status_code      = jqXHR.status
      true_status_code = jqXHR.getResponseHeader('X-True-Statuscode') ? null

      # The error response comes back as HTML, which we need to pull apart
      # into a meaningful message of some sort using jQuery.
      tmp            = $('<div />').html(jqXHR.responseText)
      @errors.title   = tmp.find('h1:first').text()
      @errors.desc    = tmp.find('p')
      @errors.details = tmp.find('ol:first').html() or ''

      # If there are multiple error descriptions then combine them into one
      # string
      if @errors.desc.length > 0
        @errors.desc = _.map(@errors.desc, (desc) -> $(desc).text()).join(' ')
      else
        @errors.desc = ''

      # We need to check the error message for lists (ol/ul). Some of the
      # services incorrectly send back <ul>s so we need to check both, or
      # set details to null if neither are present.
      if @errors.details.length == 0
        @errors.details = tmp.find('ul:first').html() or ''
        if @errors.details.length == 0
          @errors.details = null

      tmp = null # reset the container

      # If we didn't receive an X-True-Statuscode header then we prepend the
      # HTTP status code to the title.
      if !true_status_code?
        @errors.title = "#{@errors.title} (#{status_code})"

      @errors

    # **Parse error message from JSON embedded in HTML response**
    # Make the rate validation override form available if this is a rate
    # validation issue.
    #
    # @param `jqXHR` _Object_ XHR object
    # @param `json` _String_ JSON encoded text
    # @return _Object_ Error object
    #
    errorParseJSON : (jqXHR, json) ->
      if json? && json[0]?
        response = null
        try
          response = JSON.parse(json[0])
        catch e
          return @errorParseHTML jqXHR

      if response? && response[0]?
        @errors.title   = response[0].message ? null
        @errors.desc    = response[0].detail ? null
        @errors.details = null

      if @errors.title == 'Rate Validation Failed'
        @$el.find('#rate_validation_override').fadeIn('fast')

      @errors

    # **Display error message**
    # Build an error message from the error object provided by callbackError
    #
    # @param `type` _String_ warning|notice
    # @param `error` _Object_ Collection of error fragments for assembly
    #
    displayError : (type, error) ->
      msg = "<h3>#{error.title}</h3><p>#{error.desc}</p>"

      # If details exist, build list container and append to msg
      if error.details?
        msg = """
            #{msg}
            <div class="error_details">
              <a href="#"><i class="icon-plus-sign"></i> Show error details</a>
              #{error.details}
            </div>
          """

      # Display the error message
      @PARENT_VIEW.displayMessage(type, msg).remove_loader()

      msg

    # We need to display the override checkbox for rate validation errors
    displayRateValidationError : ->
      $('#rate_validation_override').fadeIn('fast')
      msg = "Rate validation error - please explicitly override"
      @PARENT_VIEW.displayMessage('warning', msg, 3000).remove_loader()

    # Return a jQuery ready ID namespaced to this CID
    # ex: #view45_reasonCode
    #
    # @param _String_ id name
    # @return _String_
    makeId : (id) ->
      "##{@cid}_#{id}"
