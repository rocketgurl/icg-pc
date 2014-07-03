define [
  'collapse'
  'BaseView'
  'modules/PolicyQuickView/DocumentsCollection'
  'text!modules/PolicyQuickView/templates/tpl_documents.html'
], (collapse, BaseView, DocumentsCollection, tpl_documents) ->

  class DocumentsView extends BaseView

    initialize : (options) ->
      policy = options.policy
      documents = policy.getDocuments()

      @collection = new DocumentsCollection(documents, {
        policyUrl : "#{policy.get('urlRoot')}policies/#{policy.get('insightId')}"
      })
      @attachments = policy.getAttachments()

      # @collection.on 'reset', @render, this
      @render()

    render : ->
      templateData =
        cid         : @cid
        documents   : @collection.getGrouped()
        attachments : @attachments
      template = @Mustache.render tpl_documents, templateData
      @$('.documents-wrapper').html template
      return this
