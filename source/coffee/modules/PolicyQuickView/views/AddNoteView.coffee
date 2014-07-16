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
      'change .file-attach-input' : 'uploadFile'
      'submit .add-note-form'     : 'addNote'

    initialize : (options) ->
      @activityCollection = options.activityCollection
      @attachmentsLocation = options.attachmentsLocation
      @POLICY = policy = options.policy

      # Keep callback functions' context bound to this view
      _.bindAll this, 'addNoteSuccess', 'addNoteError', 'handleIframeLoadEvent'

      @attachments.on 'add delete', @renderAttachments, this

      # store jQuery ref to various page elements
      @cacheElements()

      # listen for iFrame load event and handle it
      @submitIframe.load @handleIframeLoadEvent

    cacheElements : ->
      @addNoteButton        = @$('.add-note-button')
      @noteTextarea         = @$('.note-text')
      @fileAttachForm       = @$('.file-attach-form')
      @attachmentsContainer = @$('.attachments-container') 
      @submitIframe         = @$('.submit-iframe')

    addNote : (e) ->
      noteValue = @noteTextarea.val() || ''
      if noteValue
        @addNoteButton.button 'loading'
        @noteData = @POLICY.postNote noteValue, @attachments.toJSON(), @addNoteSuccess, @addNoteError
      return false

    addNoteSuccess : (data, textStatus, jqXHR) ->
      @activityCollection.add @noteData
      @addNoteButton.button 'reset'
      @noteTextarea.val ''

    addNoteError : (jqXHR, textStatus, errorThrown) ->
      # console.log errorThrown
      # console.log @noteData

    handleIframeLoadEvent : (e) ->
      try
        # console.log 'IFRAME SUCCESS', e
      catch err
        # console.log 'IFRAME ERROR', err

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
        @attachments.add
          fileType  : fileType
          fileName  : fileName
          objectKey : objectKey
          location  : @attachmentsLocation

    deleteFile : (e) ->
      # console.log e

    renderAttachments : ->
      data = { attachments : @attachments.toJSON() }
      @attachmentsContainer.html @Mustache.render tpl_attachments, data
      this
