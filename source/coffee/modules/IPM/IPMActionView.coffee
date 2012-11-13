define [
  'BaseView',
  'Messenger',
  'modules/IPM/IPMChangeSet'
], (BaseView, Messenger, IPMChangeSet) ->

  # IPMActionView
  # ====  
  # IPM sub views (action views) inherit from this base view  
  class IPMActionView extends BaseView
    
    MODULE    : {} # Containing module
    VALUES    : {} # Form values
    TPL_CACHE : {} # Template Cache
    ERRORS    : {} # Manage error states from server

    ChangeSet : {} # IPMChangeSet

    tagName : 'div'

    events :
      "click form input.button" : "submit"
      "click .form_actions a"   : "goHome"
      "click fieldset h3"       : "toggleFieldset"

    initialize : (options) ->
      @PARENT_VIEW = options.PARENT_VIEW || {}
      @MODULE      = options.MODULE || {}
      @ChangeSet   = new IPMChangeSet(@MODULE.POLICY, @PARENT_VIEW.VIEW_STATE, @MODULE.USER)
      
      @options = null

      @on('ready', @ready, this)

    # **fetchTemplates** grab the model.json and view.html for processing  
    #
    # @param `policy` _Object_ PolicyModel
    # @param `action` _String_ Name of this action 
    # @param `callback` _Function_ function to call on AJAX success  
    #
    fetchTemplates : (policy, action, callback) ->
      if !policy? || !action?
        return false

      path  = "/js/#{@MODULE.CONFIG.PRODUCTS_PATH}#{policy.get('productName')}/forms/#{_.slugify(action)}"

      # Stash the files in the cache on first load
      if !_.has(@TPL_CACHE, action)          
        model = $.getJSON("#{path}/model.json")
                  .pipe (resp) -> return resp        
        view  = $.get("#{path}/view.html", null, null, "text")
                  .pipe (resp) -> return resp
        $.when(model, view).then(callback, @PARENT_VIEW.actionError)
      else
        callback(@TPL_CACHE[action].model, @TPL_CACHE[action].view)

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
      $('.labelRequired').each ->
        if !$(this).hasClass('processed') 
          $(this).append('<em>*</em>').addClass('processed')

      # Set all Enum selects to their default values
      $('select[data-value]').val ->
        $(this).attr('data-value')

      # Attach datepickers where appropriate
      date_options = 
        dateFormat : 'yy-mm-dd'

      if $.datepicker
        $('.datepicker').datepicker(date_options)

    # **Post process the preview of the form**  
    postProcessPreview : ->
      delete @viewData.preview

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
        el   = $(element)
        val  = el.val()
        name = el.attr 'name'

        # Check on data-value of <select> element  
        # 
        # _Note:_ We are explicity using '!=' instead of CoffeeScript's 
        # automatic conversion to '!==' because the values from the form
        # are all different types and we need loose comparisons to prevent 
        # writing a shit ton of explicit detections & coercion code. 
        # This could cause an issue going forward, hence the note. - DN
        #
        if el.is 'select'
          if `el.data('value') != val`
            changed.push name

        # Check on <textarea> fields.
        else if el.is 'textarea'
          if val.trim() != ''
            changed.push name
          if val.trim() == '' && el.data('hadValue')
            changed.push name

        else
          if val != element.getAttribute('value')
            changed.push name

      changed

    # Keep a cache of loaded files for this action
    processViewData : (vocabTerms, view) ->
      @TPL_CACHE[@PARENT_VIEW.VIEW_STATE] =
        model : vocabTerms
        view  : view

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

      [viewData, view]

    # **Success handling from ChangeSet**
    #
    # @param `data` _XML_ Policy XML  
    # @param `status` _String_ Status of callback  
    # @param `jqXHR` _Object_ XHR object  
    #
    callbackSuccess : (data, status, jqXHR) =>
      msg = "#{@PARENT_VIEW.VIEW_STATE} completed successfully"
      @PARENT_VIEW.displayMessage('success', msg, 12000)

      # Load returned policy into PolicyModel
      @resetPolicyModel(data, jqXHR)

      # Re-render the form
      @processView(
        @TPL_CACHE[@PARENT_VIEW.VIEW_STATE].model,
        @TPL_CACHE[@PARENT_VIEW.VIEW_STATE].view
      )

    # **Error handling from ChangeSet**
    #
    # @param `jqXHR` _Object_ XHR object  
    # @param `status` _String_ Status of callback  
    # @param `error` _String_ Error  
    #
    callbackError : (jqXHR, status, error) =>
      # If we don't get an XHR response, then something very bad has
      # happened indeed.
      if !jqXHR
        @PARENT_VIEW.displayError(
          'warning',
          'Fatal: Error received with no response from server'
        )
        return false

      if jqXHR.responseText?
        regex = /\[(.*?)\]/g
        json  = regex.exec(jqXHR.responseText)

        # If this is an endorse action and the response is JSON then there is
        # a high chance this could be a rate validation error.
        if json? && @PARENT_VIEW.VIEW_STATE == 'Endorse'
          @ERRORS = @errorParseJSON(jqXHR, json)
        else
          @ERRORS = @errorParseHTML(jqXHR)

      @displayError 'warning', @ERRORS

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
      @processPreview(
        @TPL_CACHE[@PARENT_VIEW.VIEW_STATE].model,
        @TPL_CACHE[@PARENT_VIEW.VIEW_STATE].view
      )

    # **Load new XML into PolicyModel**  
    #
    # Inject the new policy XML into the model and setModelState()
    #
    # @param `data` _XML_ PolicyModel
    # @param `jqXHR` _Object_ XHR object  
    # @return _Object_ PolicyModel
    #
    resetPolicyModel : (data, jqXHR) ->
      # Swap out Policy XML with new XML, saving the old one
      new_attributes = @MODULE.POLICY.parse(data, jqXHR)
      new_attributes.prev_document = @MODULE.POLICY.get('document')

      # Model.set() chokes on something in the object, so we just
      # jam the values into attributes directly. So sorry Mr. Ashkenas.
      for key, val of new_attributes
        @MODULE.POLICY.attributes[key] = val

      # Tell the model to set its state based on the new XML values
      @MODULE.POLICY.trigger 'change', @MODULE.POLICY

      @MODULE.POLICY

    # Your Action View should define the following methods:

    ready : ->

    # **Build view data objects and trigger loaded event**  
    #
    # Takes the model.json and creates a custom data object for this view. We
    # then trigger the `loaded` event passing @postProcessView as the callback. 
    # This will attach any necessary behaviors to the rendered form.  
    #
    # @param `vocabTerms` _Object_ model.json  
    # @param `view` _String_ HTML template    
    #
    render : (viewData, view) ->
      super
      viewData = viewData || @viewData
      view     = view || @view
      @$el.html(@MODULE.VIEW.Mustache.render(view, viewData))

    validate : ->

    preview : ->

    # **Submit form** - set the form values on the ActionView for 
    # use in inherited ActionViews. Only do this if there is an actual form,
    # otherwise we're probably in a preview state and need to hold onto the
    # original form values.
    #
    # _Note:_ This method should be extended in child views
    #
    # @param `e` _Event_ Submit event   
    #
    submit : (e) ->
      e.preventDefault()
      form = @$el.find('form')
      if form.length > 0      
        @VALUES =
          formValues    : @getFormValues form
          changedValues : @getChangedValues form

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
      @ERRORS.title   = tmp.find('h1:first').text()
      @ERRORS.desc    = tmp.find('p:first').text()
      @ERRORS.details = tmp.find('ol:first')

      # We need to check the error message for lists (ol/ul). Some of the 
      # services incorrectly send back <ul>s so we need to check both, or
      # set details to null if neither are present.
      if @ERRORS.details.length == 0
        @ERRORS.details = tmp.find('ul:first')
        if @ERRORS.details.length == 0
          @ERRORS.details = null

      tmp = null # reset the container

      # If we didn't receive an X-True-Statuscode header then we prepend the
      # HTTP status code to the title.
      if !true_status_code?
        @ERRORS.title = "#{status_code} #{@ERRORS.tile}"

      @ERRORS

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
        response = JSON.parse(json[0]) ? null

      if response[0]?
        @ERRORS.title   = response[0].message ? null
        @ERRORS.desc    = response[0].detail ? null
        @ERRORS.details = null

      if @ERRORS.title == 'Rate Validation Failed'
        @$el.find('#rate_validation_override').fadeIn('fast')

      @ERRORS



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
      @PARENT_VIEW.displayMessage(type, msg)

      msg
