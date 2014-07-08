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
      attachments = policy.getAttachments()

      @collection = new DocumentsCollection(documents.concat(attachments), {
        policyUrl : "#{policy.get('urlRoot')}policies/#{policy.get('insightId')}"
      })

      # @collection.on 'reset', @render, this
      @render()

    render : ->
      data =
        cid         : @cid
        docGroups   : @collection.getGrouped()
        attachments : @attachments
      console.log data
      template = _.template tpl_documents
      @$('.documents-wrapper').html template(data)
      return this
