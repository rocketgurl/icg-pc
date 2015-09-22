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

    # used to replace evil MS Word characters in the notes field
    msCharMap :
      '\u2013'  : '--'  # "–"
      '\u2014'  : '--'  # "—"
      '\u2018'  : '\''  # "‘"
      '\u2019'  : '\''  # "’"
      '\u201c'  : '"'   # "“"
      '\u201d'  : '"'   # "”"
      '\u2022'  : '*'   # "•"
      '\u2026'  : '...' # "…"

    initialize : (options) ->
      @attachmentsLocation = options.attachmentsLocation
      @POLICY = policy = options.policy
      @qvid = options.qvid

      # Keep callback functions' context bound to this view
      _.bindAll(this
        'addNoteError'
        'addNoteSuccess'
        'deleteFileError'
        'deleteFileSuccess'
        'handleIframeLoadEvent'
        )

      @attachments.on 'add remove reset', @renderAttachments, this

      # store jQuery refs to various DOM elements
      @cacheElements()

      # listen for iFrame load event and handle it
      @attachIframe.load @handleIframeLoadEvent

    cacheElements : ->
      @attachmentsContainer = @$('.attachments-container')
      @fileAttachInput      = @$('.file-attach-input')
      @fileAttachForm       = @$('.file-attach-form')
      @fileAttachLink       = @$('.file-attach-link')
      @addNoteButton        = @$('.add-note-button')
      @attachIframe         = @$("iframe[name=attach-iframe-#{@qvid}]")
      @noteText             = @$('.note-text')

    sanitizeMSChars : (input) ->
      output = input
      try
        _.each @msCharMap, (replace, search) ->
          search = new RegExp search, 'g'
          output = output.replace search, replace
        output
      catch
        input

    addNote : (e) ->
      noteValue = @noteText.val() || ''
      if noteValue
        @addNoteButton.button 'loading'
        noteValue = @sanitizeMSChars noteValue
        @noteData = @POLICY.postNote noteValue, @attachments.toJSON(), @addNoteSuccess, @addNoteError
      return false

    addNoteSuccess : ->
      @POLICY.refresh()
      @attachments.reset()
      @addNoteButton.button 'reset'
      @noteText.val ''

    # TODO: something here
    addNoteError : (jqXHR, textStatus, errorThrown) ->
      # Log a hopefully useful ajax error for TrackJS
      info = ""
      try
        info = """
Add Note XMLHTTPResponse Error (#{jqXHR.status}) #{jqXHR.statusText}
ResponseHeaders: #{jqXHR.getAllResponseHeaders()}
        """
        throw new Error "Add Note Error"
      catch ex
        console.info info

    deleteFileSuccess : (modelId) ->
      =>
        attachmentModel = @attachments.getByCid modelId
        @attachments.remove attachmentModel
        @addNoteButton.button 'reset'

    deleteFileError : (jqXHR, textStatus, errorThrown) ->
      # console.log 'err'

    handleIframeLoadEvent : (e) ->
      @addNoteButton.button 'reset'

    triggerFileDialog : (e) ->
      @fileAttachInput.trigger 'click'
      e.preventDefault()

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

      params =
        url         : e.currentTarget.href
        type        : 'DELETE'
        contentType : 'application/xml'
        headers     :
          'Authorization'     : "Basic #{@POLICY.get('digest')}"
          'x-crippled-client' : 'yes'
          'x-rest-method'     : 'DELETE'

      jqXHR = $.ajax params
      $.when(jqXHR).then @deleteFileSuccess(e.currentTarget.id), @deleteFileError
      @addNoteButton.button 'loading'

    renderAttachments : ->
      data = { attachments : @attachments.toJSON() }
      @attachmentsContainer.html @Mustache.render tpl_attachments, data
      @fileAttachLink[if data.attachments.length then 'addClass' else 'removeClass']('toggle')
      this
