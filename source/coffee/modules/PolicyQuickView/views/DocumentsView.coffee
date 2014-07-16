define [
  'collapse'
  'BaseView'
  'modules/PolicyQuickView/collections/DocumentsCollection'
  'text!modules/PolicyQuickView/templates/tpl_documents.html'
], (collapse, BaseView, DocumentsCollection, tpl_documents) ->

  class DocumentsView extends BaseView

    initialize : (options) ->
      @POLICY = policy = options.policy
      documents = policy.getDocuments()
      attachments = policy.getAttachments()

      @collection = new DocumentsCollection(documents.concat(attachments), {
        policyInceptionDate : policy.getInceptionDate()
        policyUrl           : policy.url()
      })

      @collection.on 'reset', @render, this
      @POLICY.on 'change:version', @handlePolicyRefresh, this
      @render()

    handlePolicyRefresh : ->
      documents   = @POLICY.getDocuments()
      attachments = @POLICY.getAttachments()
      @collection.reset documents.concat(attachments)

    render : ->
      data =
        cid         : @cid
        docGroups   : @collection.getGrouped()
      template = _.template tpl_documents
      @$('.documents-wrapper').html template(data)
      return this
