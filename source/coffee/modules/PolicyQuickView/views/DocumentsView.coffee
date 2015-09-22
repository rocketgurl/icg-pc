define [
  'collapse'
  'BaseView'
  'modules/PolicyQuickView/collections/DocumentsCollection'
  'text!modules/PolicyQuickView/templates/tpl_documents.html'
], (collapse, BaseView, DocumentsCollection, tpl_documents) ->

  class DocumentsView extends BaseView

    uploads : []

    events :
      'click  .file-upload-link'  : 'triggerFileDialog'
      'change .file-upload-input' : 'uploadFile'

    initialize : (options) ->
      @POLICY = policy = options.policy
      @attachmentsLocation = options.attachmentsLocation
      @qvid = options.qvid
      documents = policy.getDocuments()
      attachments = policy.getAttachments()

      _.bindAll this, 'addDocument', 'addDocumentSuccess', 'addDocumentError'

      @collection = new DocumentsCollection(documents.concat(attachments), {
        policyInceptionDate : policy.getInceptionDate()
        policyUrl           : policy.url()
      })

      # store jQuery refs to various DOM elements
      @cacheElements()

      # listen for iFrame load event and handle it
      @uploadIframe.load @addDocument

      @collection.on 'reset', @render, this
      @POLICY.on 'change:refresh change:version', @handlePolicyRefresh, this
      @render()

    cacheElements : ->
      @documentsWrapper = @$('.documents-wrapper')
      @fileUploadInput  = @$('.file-upload-input')
      @fileUploadForm   = @$('.file-upload-form')
      @fileUploadLink   = @$('.file-upload-link-container')
      @uploadIframe     = @$("iframe[name=upload-iframe-#{@qvid}]")

    handlePolicyRefresh : ->
      documents   = @POLICY.getDocuments()
      attachments = @POLICY.getAttachments()
      @collection.reset documents.concat(attachments)

    triggerFileDialog : (e) ->
      @fileUploadInput.trigger 'click'
      e.preventDefault()

    addDocument : (e) ->
      if @uploads.length
        @POLICY.postNote '', @uploads, @addDocumentSuccess, @addDocumentError

    addDocumentSuccess : ->
      @POLICY.refresh()
      @uploads = []
      @fileUploadLink.removeClass 'toggle'

    # TODO: something here
    addDocumentError : (jqXHR, textStatus, errorThrown) ->
      @fileUploadLink.removeClass 'toggle'
      
      # Log a hopefully useful ajax error for TrackJS
      info = ""
      try
        info = """
Add Document XMLHTTPResponse Error (#{jqXHR.status}) #{jqXHR.statusText}
ResponseHeaders: #{jqXHR.getAllResponseHeaders()}
        """
        throw new Error "Add Document Error"
      catch ex
        console.info info

    uploadFile : (e) ->
      files = _.toArray e.currentTarget.files
      if files?.length
        file = files[0]
        fileType = file.type
        fileName = file.name
        fileExt = fileName.substring fileName.lastIndexOf '.'
        objectKey = @Helpers.createGUID() + fileExt

        @fileUploadForm.find('input[name=object-key]').val objectKey
        @fileUploadForm.submit()
        @fileUploadLink.addClass 'toggle'

        @uploads = [
          fileType  : fileType
          fileName  : fileName
          objectKey : objectKey
          location  : @attachmentsLocation
        ]

    # This template got WAAY too unwieldy trying to work
    # around Mustache's bizarre constraints. Using Underscore's
    # `_.template` for a **far** simpler, more robust solution.
    # F*** "Logicless" templating in the A**!!
    render : ->
      data =
        cid         : @cid
        qvid        : @qvid
        docGroups   : @collection.getGrouped()

      docsTemplate = _.template tpl_documents
      @documentsWrapper.html docsTemplate(data)
      this
