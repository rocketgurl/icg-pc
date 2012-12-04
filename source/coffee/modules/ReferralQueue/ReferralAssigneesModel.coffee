define [
  'BaseModel'
], (BaseModel) ->

  ReferralAssigneesModel = BaseModel.extend

    initialize : ->
      @use_cripple()

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

      if typeof xml != 'string'
        xml = @Helpers.XMLToString xml

      $.ajax
        url         : @url
        type        : 'PUT'
        dataType    : 'xml'
        contentType : 'application/xml'
        data        : xml
        headers     :
          'Authorization'     : "Basic #{@get('digest')}"
          'X-Authorization'   : "Basic #{@get('digest')}"
          'X-Crippled-Client' : "yes"
          'X-Rest-Method'     : "PUT"
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
      errors =
        statuscode  : xhr.getResponseHeader('X-True-Statuscode')
        status_code : xhr.getResponseHeader('X-True-Status-Code')
        statustext  : xhr.getResponseHeader('X-True-Statustext')
        status_text : xhr.getResponseHeader('X-True-Status-Text')
        msg         : xhr.getResponseHeader('X-Error-Message')

      # Cripple Client: anything other than X-True-Statuscode 200 is a fail
      if errors.statuscode? || errors.status_code?
        code = errors.statuscode ? errors.status_code
        text = errors.statustext ? errors.status_text
        if code != '200'
          model.trigger 'fail', "#{code} #{text}"
          return model

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
        # Guard rails
        new_business = renewals = false
        if _.has(item, 'new_business')
          new_business = JSON.parse(item.new_business)
        if _.has(item, 'renewals')
          renewals = JSON.parse(item.renewals)

        {
          identity     : item.identity
          active       : JSON.parse(item.active)
          new_business : new_business
          renewals     : renewals
        }

    # **Convert Assignees JSON to XML**  
    # 
    # @return _String_  
    #
    json2xml : ->
      json = @get('json')

      nodes = ""      
      for assignee in json.Assignee

        assignee.new_business ?= false
        assignee.renewals ?= false

        nodes += """<Assignee identity="#{assignee.identity}" active="#{assignee.active}" new_business="#{assignee.new_business}" renewals="#{assignee.renewals}" />"""

      "<AssigneeList>#{nodes}</AssigneeList>"
