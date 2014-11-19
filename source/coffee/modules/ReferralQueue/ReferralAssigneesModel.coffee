define [
  'BaseModel'
], (BaseModel) ->

  ReferralAssigneesModel = BaseModel.extend

    initialize : ->
      @use_cripple()

    getAll : ->
      @parseBooleans @get('json').Assignee

    getRenewals : ->
      json = @parseBooleans @get('json').Assignee
      _.where json, { renewals : true }

    getNewBusiness : ->
      json = @parseBooleans @get('json').Assignee
      _.where json, { new_business : true }

    # **PUT XML to server and fire callbacks**
    #
    # @return _jqXHR_
    #
    putList : (success, error) ->
      xml = @json2xml()
      success ?= @putSuccess
      error  ?= @putError

      unless _.isString xml
        xml = @Helpers.XMLToString xml

      $.ajax
        url         : @url
        type        : 'PUT'
        dataType    : 'xml'
        contentType : 'application/xml'
        data        : xml
        headers     :
          'Authorization'   : "Basic #{@get('digest')}"
          'X-Authorization' : "Basic #{@get('digest')}"
        success : (data, textStatus, jqXHR) =>
          if success?
            success.apply(this, [this, data, textStatus, jqXHR])
        error: (jqXHR, textStatus, errorThrown) =>
          if error?
            error.apply(this, [this, jqXHR, textStatus, errorThrown])

    # Success Callback for putList - updates model with new XML
    #
    # @param `model` _Object_ ReferralAssigneesModel
    # @param `data` _XML_ Response from server
    # @param `status` _String_ HTTP success/fail
    # @param `xhr` _jqXHR_ jQuery XHR object
    #
    putSuccess : (model, data, textStatus, xhr) ->
      parsed_data = model.parse(data, xhr)
      for key, val of parsed_data
        model.attributes[key] = val
      model.trigger 'change', model

      model

    # Error Callback for putList - PUT bailed out. This is a no-op and should
    # be implemented in ReferralQueueView (to display error messages, etc)
    #
    # @param `model` _Object_ ReferralAssigneesModel
    # @param `xhr` _jqXHR_ jQuery XHR object
    # @param `textStatus` _String_ Error code
    # @param `errorThrown` _String_ Error msg
    #
    putError : (model, xhr, textStatus, errorThrown) ->
      model.trigger 'fail', errorThrown

    # Turn string representations of booleans into actual booleans. If we don't
    # have the new attributes (new_business & renewals) then we add them.
    parseBooleans : (arr) ->
      arr = _.map arr, (item) ->
        out = _.clone item
        if _.has out, 'new_business'
          out.new_business = JSON.parse out.new_business
        if _.has out, 'renewals'
          out.renewals = JSON.parse out.renewals
        if _.has out, 'active'
          out.active = JSON.parse out.active
        out

    # **Convert Assignees JSON to XML**
    #
    # @return _String_
    #
    json2xml : ->
      json = @get('json')

      nodes = "\n"
      for assignee in json.Assignee
        nodes += "  "
        nodes += """<Assignee identity="#{assignee.identity}" active="#{assignee.active}" """
        nodes += """new_business="#{assignee.new_business}" """ if _.has assignee, 'new_business'
        nodes += """renewals="#{assignee.renewals}" """ if _.has assignee, 'renewals'
        nodes += "/>\n"

      "<AssigneeList>#{nodes}</AssigneeList>"
