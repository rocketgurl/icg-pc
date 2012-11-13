define [
  'BaseView',
  'Messenger',
  'modules/IPM/IPMChangeSet'
], (BaseView, Messenger, IPMChangeSet) ->

  # IPMActionView
  # ====  
  # IPM sub views (action views) inherit from this base view 
  class IPMActionView extends BaseView
    
    MODULE     : {} # Containing module
    VALUES     : {} # Form values
    TPL_CACHE  : {} # Template Cache
    CHANGE_SET : {}

    tagName : 'div'

    events :
      "click form input.button" : "submit"
      "click .form_actions a"   : "goHome"
      "click fieldset h3"       : "toggleFieldset"

    initialize : (options) ->
      @PARENT_VIEW = options.PARENT_VIEW || {}
      @MODULE      = options.MODULE || {}
      @CHANGE_SET  = new IPMChangeSet(@MODULE.POLICY, @PARENT_VIEW.VIEW_STATE, @MODULE.USER)
      
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
      $('.labelRequired').append('<em>*</em>')

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

    callbackSuccess : (data, status, jqXHR) =>
      console.log jqXHR
     
    callbackError : (jqXHR, status, error) =>
      console.log jqXHR

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
      # Swap out Policy XML with new XML, saving the old one
      prev_document             = @MODULE.POLICY.get('document')
      @MODULE.POLICY.attributes = @MODULE.POLICY.parse(data, jqXHR)

      # Tell the model to set its state based on the new XML values
      if @MODULE.POLICY.set('prev_document', prev_document)
        @MODULE.POLICY.setModelState()

      @processPreview(
        @TPL_CACHE[@PARENT_VIEW.VIEW_STATE].model,
        @TPL_CACHE[@PARENT_VIEW.VIEW_STATE].view
      )

    # Your Action View should define the following methods:

    ready : ->

    render : -> 

    validate : ->

    preview : ->

    # **Submit form** - set the form values on the ActionView for 
    # use in inherited ActionViews
    #
    # @param `e` _Event_ Submit event   
    #
    submit : (e) ->
      e.preventDefault()
      form = @$el.find('form')      
      @VALUES =
        formValues    : @getFormValues form
        changedValues : @getChangedValues form

