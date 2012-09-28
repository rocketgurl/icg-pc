define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  #### Policy
  #
  # We handle Policy XML here
  #
  PolicyModel = BaseModel.extend

    initialize : ->
      @use_cripple() # Use CrippledClient XMLSync

    url : ->
      return @get('urlRoot') + 'policies/' + @id

    # **Get the numeric portion of policy id used in pxServer**  
    # @return _String_
    get_pxServerIndex : ->
      doc = @get 'document'
      @set 'pxServerIndex', doc.find('Identifiers Identifier[name=pxServerIndex]').attr('value')
      @get 'pxServerIndex'

    # **Build a last, first policy holder name**  
    # @return _String_
    get_policy_holder : ->
      doc = @get 'document'
      last = doc.find('Customers Customer[type=Insured] DataItem[name=OpInsuredLastName]').attr('value')
      first = doc.find('Customers Customer[type=Insured] DataItem[name=OpInsuredFirstName]').attr('value')
      "#{last}, #{first}"

    # **Build a policy period date range for use in IPM header**  
    # @return _String_
    get_policy_period : ->
      doc   = @get 'document'
      start = doc.find('Terms Term EffectiveDate').text().substr(0,10)
      end   = doc.find('Terms Term ExpirationDate').text().substr(0,10)
      "#{start} - #{end}"

    # **Build an object containing information for the IPM header**  
    # @return _Object_
    get_ipm_header : ->
      doc = @get 'document'
      ipm_header =
        id      : doc.find('Identifiers Identifier[name=PolicyID]').attr('value')
        product : doc.find('Terms Term DataItem[name=OpProductLabel]').attr('value')
        holder  : @get_policy_holder()
        state   : doc.find('Management PolicyState').text()
        period  : @get_policy_period()
        carrier : doc.find('Management Carrier').text()
      ipm_header

    # **Get <SystemOfRecord>** - used to determine IPM eligibility.  
    # @return _String_
    getSystemOfRecord : ->
      @get('document').find('Management SystemOfRecord').text()

    # **Is this an IPM policy?**  
    # @return _Boolean_
    isIPM : ->
      if @getSystemOfRecord == 'mxServer' then true else false    

      
  PolicyModel