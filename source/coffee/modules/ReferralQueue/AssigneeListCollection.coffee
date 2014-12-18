define [
  'backbone'
  'modules/ReferralQueue/AssigneeModel'
], (Backbone, AssigneeModel) ->

  class AssigneeListCollection extends Backbone.Collection

    model : AssigneeModel

    url : ->
      if _.isObject (ixlibrary = @controller.services.ixlibrary)
        "#{ixlibrary.baseURL}/buckets/#{ixlibrary.underwritingBucket}/objects/#{ixlibrary.assigneeListObjectKey}"

    sync : (method, collection, options) ->
      options = _.extend options,
        dataType    : 'xml'
        contentType : 'application/xml'
        headers     :
          'Accept'        : 'application/xml'
          'Authorization' : "Basic #{@controller.user.get('digest')}"
      Backbone.sync method, collection, options
      @trigger 'request', this

    # **Hook into native sync to PUT XML and fire callbacks**
    update : ->
      if @length > 0
        options =
          processData : false
          data        : @toXML()
          success     : @updateSuccess
          error       : @updateError
        @sync 'update', this, options

    # **Convert XML to collection of JS Objects to populate Collection**
    parse : (response, xhr) ->
      data = $.fn.xml2json xhr.responseText
      unless _.isArray data.Assignee
        data.Assignee = []
      data.Assignee

    initialize : ->
      _.bindAll this, 'updateSuccess', 'updateError'

    # **Convert Assignee Models to XML String**
    #
    # @return _String_
    toXML : ->
      nodes = "\n"
      @each (model) ->
        attributes = model.toJSON()
        nodes += """  <Assignee """
        _.each attributes, (val, key) ->
          nodes += """#{key}="#{val}" """
        nodes += "/>\n"
      "<AssigneeList>#{nodes}</AssigneeList>"

    # Success Callback for update - PUTS new XML to server
    #
    # @param `data` _XML_ Response from server
    # @param `textStatus` _String_ HTTP success/fail
    # @param `jqXHR` _jqXHR_ jQuery XHR object
    updateSuccess : (data, textStatus, jqXHR) ->
      @trigger 'success', this, jqXHR

    # Error Callback for update
    #
    # @param `jqXHR` _jqXHR_ jQuery XHR object
    # @param `textStatus` _String_ HTTP success/fail
    # @param `errorThrown` _String_ Text description of error
    updateError: (jqXHR, textStatus, errorThrown) ->
      @trigger 'error', this, jqXHR
