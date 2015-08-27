define [
  'BaseModel'
], (BaseModel) ->

  #### User
  #
  # We handle ixDocument identities here
  #
  UserModel = BaseModel.extend

    initialize : ->
      @on 'change', @applyFunctions

      @use_cripple() # Use CrippledClient XMLSync

      @urlRoot = @get 'urlRoot'

      # Username is ID
      if @get 'username'
        @id = @get 'username'

      # Create a digest for basic auth and remove password
      if @get('username') and @get('password')
        @set {'digest' : @Helpers.createDigest @get('username'), @get('password')}
        delete @attributes.password

    # Does the actual partial application
    applyFunctions : (model, options) ->
      @find = _.partial @findProperty, @get('json')

    # Additional document parsing to load up User with more accessible
    # information (pulling attrs out of parsed XML and into model.attributes)
    #
    parse_identity : ->
      @set 'passwordHash', @find('passwordHash')
      @set 'name', @find('Name')
      @set 'email', @find('Email')

    # True if User has ixadmin > PoliciesModule > Rights > Right > VIEW_ADVANCED
    canViewAdvanced : ->
      _.contains(
        @findProperty(
          _.findWhere(@get('json').ApplicationSettings, {
            environmentName: ICS360_ENV,
            applicationName : 'ixadmin'}),
          'PoliciesModule Rights Right'),
        'VIEW_ADVANCED')

    # True if User has ixadmin > PoliciesModule > Rights > Right > IPM_ACTIONS
    canViewIPM : ->
      _.contains(
        @findProperty(
          _.findWhere(@get('json').ApplicationSettings, {
            environmentName: ICS360_ENV,
            applicationName : 'ixadmin'}),
          'PoliciesModule Rights Right'),
        'IPM_ACTIONS')

    # Is this a carrier user? (ICS-2019)
    isCarrier : ->
      _.where(@find('Affiliation'),
              { type : 'employee_carriergroup' }).length > 0


  UserModel
