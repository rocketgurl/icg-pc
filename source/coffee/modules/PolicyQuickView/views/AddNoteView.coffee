define [
  'collapse'
  'button'
  'BaseView'
  'modules/PolicyQuickView/collections/AttachmentsCollection'
  'text!modules/PolicyQuickView/templates/tpl_attachments.html'
], (collapse, button, BaseView, AttachmentsCollection, tpl_attachments) ->

  class AddNoteView extends BaseView

    attachments : new AttachmentsCollection()

    events :
      'click  .file-attach-link'  : 'triggerFileDialog'
      'click  .file-delete-link'  : 'deleteFile'
      'change .file-attach-input' : 'uploadFile'
      'submit .add-note-form'     : 'addNote'

    initialize : (options) ->
      @activityCollection = options.activityCollection
      @attachmentsLocation = options.attachmentsLocation
      @POLICY = policy = options.policy

      # Keep callback functions' context bound to this view
      _.bindAll this, 'addNoteSuccess', 'addNoteError', 'handleIframeLoadEvent'

      @attachments.on 'add remove reset', @renderAttachments, this

      # store jQuery refs to various DOM elements
      @cacheElements()

      # listen for iFrame load event and handle it
      @submitIframe.load @handleIframeLoadEvent

    cacheElements : ->
      @attachmentsContainer = @$('.attachments-container') 
      @fileAttachForm       = @$('.file-attach-form')
      @addNoteButton        = @$('.add-note-button')
      @submitIframe         = @$('.submit-iframe')
      @noteTextarea         = @$('.note-text')

    addNote : (e) ->
      noteValue = @noteTextarea.val() || ''
      if noteValue
        @addNoteButton.button 'loading'
        @noteData = @POLICY.postNote noteValue, @attachments.toJSON(), @addNoteSuccess, @addNoteError
      return false

    addNoteSuccess : (data, textStatus, jqXHR) ->
      @POLICY.refresh()
      @attachments.reset()
      @addNoteButton.button 'reset'
      @noteTextarea.val ''

    # TODO: something here
    addNoteError : (jqXHR, textStatus, errorThrown) ->
      # console.log errorThrown
      # console.log @noteData

    handleIframeLoadEvent : (e) ->
      @addNoteButton.button 'reset'

    triggerFileDialog : (e) ->
      e.preventDefault()
      @$('.file-attach-input').trigger 'click'

    # Files posted to ixlibrary
    # In order to post a file in a cross-browser friendly way,
    # we set some input values and kick off a form post (not ajax)
    # targeted at a hidden iframe. Then listen to iframe for the load event
    uploadFile : (e) ->
      files = _.toArray e.currentTarget.files
      if files?.length
        file = files[0]
        fileType = file.type
        fileName = file.name
        fileExt = fileName.substring fileName.lastIndexOf '.'
        objectKey = @Helpers.createGUID() + fileExt

        @fileAttachForm.find('input[name=object-key]').val objectKey
        @fileAttachForm.submit()
        @addNoteButton.button 'loading'
        @attachments.add
          fileType  : fileType
          fileName  : fileName
          objectKey : objectKey
          location  : @attachmentsLocation

        # HTML FileList API prevents adding duplicate files
        # However, it's possible we will delete the file,
        # and then change our mind, so clear the FileList
        # by setting the value to an empty string
        e.currentTarget.value = ''

    deleteFile : (e) ->
      e.preventDefault()
      attachmentId = e.currentTarget.id

      successCallback = =>
        attachmentModel = @attachments.getByCid e.currentTarget.id
        @attachments.remove attachmentModel
        @addNoteButton.button 'reset'

      errorCallback = ->
        # console.log 'err'

      params =
        url         : e.currentTarget.href
        type        : 'DELETE'
        contentType : 'application/xml'
        headers     :
          'Authorization'     : "Basic #{@POLICY.get('digest')}"
          'x-crippled-client' : 'yes'
          'x-rest-method'     : 'DELETE'

      jqXHR = $.ajax params
      $.when(jqXHR).then successCallback, errorCallback
      @addNoteButton.button 'loading'

    renderAttachments : ->
      data = { attachments : @attachments.toJSON() }
      @attachmentsContainer.html @Mustache.render tpl_attachments, data
      this
