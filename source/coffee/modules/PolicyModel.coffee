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

    get_pxServerIndex : ->
      doc = @get 'document'
      @set 'pxServerIndex', doc.find('Identifiers Identifier[name=pxServerIndex]').attr('value')

    get_policy_holder : ->
      doc = @get 'document'
      last = doc.find('Customers Customer[type=Insured] DataItem[name=AdditionalInsured1LastName]').attr('value')
      first = doc.find('Customers Customer[type=Insured] DataItem[name=AdditionalInsured1FirstName]').attr('value')
      "#{last}, #{first}"

    get_policy_period : ->
      doc   = @get 'document'
      start = doc.find('Terms Term EffectiveDate').text().substr(0,10)
      end   = doc.find('Terms Term ExpirationDate').text().substr(0,10)
      "#{start} - #{end}"

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

      
  PolicyModel