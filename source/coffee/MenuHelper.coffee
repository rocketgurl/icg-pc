define [
  'jquery',
  'underscore'
], ($, _) ->

  #### Menu Helper
  #
  # This is a set of methods to help build the Workspace Menu
  # by parsing the CthulhuXML of ixDirectory and ixAdmin
  # 
  MenuHelper = 

    # Store our XML documents
    identity           : null
    ixconfig           : null
    tentacles          : null
    menu               : null
    contexts           : null
    businesses         : null
    app_to_context_map : null

    #### Build Menu
    #
    # Iterate over the ixDirectory tentacles and ixAdmin
    # items to generate the workspace menu hierarchy
    #
    # @param **identity** _Object_ ixDirectory document
    # @param **ixconfig** _Object_ ixConfig document
    #
    build_menu : (identity, ixconfig) ->

      @identity = identity.Identity
      @ixconfig = ixconfig.ixConfig

      # Get a nice object of business names from ixConfig
      @businesses = @get_config_item(@ixconfig, 'businesses')
      business_names = {}
      _.each @businesses.ConfigItem, (business) ->
        business_names[business['-name']] = business['-value']
      @businesses = business_names

      # These are the current possible contexts from ixConfig arranged
      # in an easy to access object by label (ex: cru, cruwic, etc)
      @contexts = @build_context_map(@get_config_item(@ixconfig, 'contexts'))

      # We need to generate an object that easily lets us map
      # different app names to their correct context
      @app_to_context_map = @get_context_map(@contexts)
      
      # Parse the tentacles from ixDirectory and build an
      # array of the valid ones
      @tentacles = @get_tentacles(@get_ixadmin(@identity)[0])

      # Now assemble the building blocks into something usable
      compiled_menu = @compile_menu_collection(@businesses, @tentacles, @contexts)

      @generate_menu compiled_menu

      # @collection = @collect_tentacles_by_context(@contexts, @tentacles)
      # console.log @collection

      # #@menu     = @generate_menu(@ixadmin, @get_labels(@ixconfig))
      # console.log @businesses
      # console.log @contexts
      # #console.log @context_map
      # console.log @app_to_context_map
      # console.log @tentacles

    generate_menu : (tree) ->
      console.log tree

    #### Compile Menu Collection
    #
    # Iterate over our building blocks and create a tree
    # of Businesses -> Contexts -> Applications
    #
    # @param **businesses** _Object_ businesses map
    # @param **tentacles** _Object_ tentacle collection
    # @param **contexts** _Object_ context collection
    #
    compile_menu_collection : (businesses, tentacles, contexts) ->
      bc = {} # bidness collection
      for business_name, business_label of businesses
        bc[business_name] = { label : business_label, contexts : null }

        # Get all apps in this business
        apps = []
        for t_name, t_val of tentacles          
          if t_val.business? and t_val.business is business_name
            apps.push t_val

        # Get all contexts from these apps
        groups = {}
        for app in apps
          if !_.has groups, app.context.context
            groups[app.context.context] = 
              label : contexts[app.context.context].label
              apps : []
            groups[app.context.context].apps.push app
          else
            groups[app.context.context].apps.push app
        bc[business_name].contexts = groups

      bc

    #### Collect Tentacles By Context
    #
    # Iterate over context and see if we have tentacles
    # for nodes. If we do, then create a hash of those
    # tentacles arranged by context.
    #
    # @param **contexts** _Object_ @contexts
    # @param **tentacles** _Object_ @tentacles
    #
    collect_tentacles_by_context : (contexts, tentacles) ->
      collection = {}

      # Hairy loop
      _.each contexts, (context, name) =>
        collection[name] = { label : context.label }
        if context.applications?
          apps = {}
          _.each context.applications, (app, app_name) =>
            if app_name? and app?
              if _.has tentacles, app_name
                apps[app_name] = app
              if app.businesses? and app.businesses['-name']
                collection[name]['business'] = app.businesses['-name']
          
          if _.keys(apps).length > 0
            collection[name].applications = apps

      # Remove items with no applications
      _.each collection, (val, name) =>
        if !_.has val, 'applications'
          delete collection[name]

      collection


    #### Get Tentacles
    #
    # Iterate over ixadmin node to extract tentacleLink nodes
    # and split into named pices for further processing
    #
    # @param **data** _Object_ ixAdmin node
    #
    get_tentacles : (data) ->
      re = RegExp window.ICS360_ENV, "gi"

      tentacles = _.filter data.tentacleLink, (item) ->
        item['-path'].match(re)

      # Take the tentacle path and process it, looking for valid
      # contexts (from ixConfig) and attempt to derive the correct
      # application name, etc.
      #
      # Example path: staging-fnic-rulesets_fnic
      # Example expl: {env}-{business}-{app}
      #
      processed_tentacles = _.map tentacles, (val, key) =>
        tentacle  = val['-path']
        pieces    = tentacle.split '-'        
        [env, business, app] = [pieces[0], pieces[1], pieces[2]]

        if _.has @app_to_context_map, app
          app_label = @app_to_context_map[app].label
        else
          return null

        context = @app_to_context_map[app]

        # Introspect the contexts to get the real business unit
        # these tentacles belong to. We need this to round up
        # tentacle apps by context/business
        #
        if context? and context.businesses?
          if _.isArray context.businesses
            business = _.pluck context.businesses, '-name'
          else if _.isObject context.businesses
            business = context.businesses['-name']

        {
          'env'       : env
          'business'  : business
          'app'       : app
          'app_label' : app_label
          'context'   : context
          'tentacle'  : tentacle
        }

      # Return clean array
      processed_tentacles = _.filter processed_tentacles, (item) ->
        item?

      out = {}

      # format the object a little better
      for tentacle in processed_tentacles
        out[tentacle.app] = tentacle

      out


    #### Build Context Map
    #
    # Intense data massage. Moves contexts XML into a
    # more rational JSON style format. **This is hairy.**
    #
    # Output:
    # 
    # contexts : {
    #   cru : {
    #     applications : {
    #       policies_cru : [],
    #       rulesets_cru : []
    #     },
    #     label : "CRU Surplus Residential and Commercial"
    #   },
    #   ...
    # }
    #
    # @param **data** _Object_ @contexts collection
    #  
    build_context_map : (data) ->
      context = {}

      # Loop over each ConfigItem
      _.each data.ConfigItem, (item, context_key) =>

        # Create a name object (ex: cruwic)
        item_label = @get_config_item(item, 'label')

        # If this has an applications node then parse it
        if item.ConfigItem['-name']? and item.ConfigItem['-name'] == 'applications'
          item_apps = item.ConfigItem.ConfigItem
        else
          item_apps = @get_config_item item, 'applications'

        # Named object to store context info
        context[item['-name']] = {}

        # Grab the label name if it exists
        if item_label?
          context[item['-name']].label = item_label['-value']

        # Storage object for applications
        applications = {}

        # Loop over the applications nodes and build properly
        # named objects to store the data in. Somtimes the application
        # node is a single object, sometimes and array of objects.
        _.each item_apps, (app) ->

          if _.isObject(app) and app['-name'] != 'undefined'
            applications[app['-name']] = app.ConfigItem

          if _.isArray(app)
            _.each app, (single_app) ->
              if single_app['-name'] != 'undefined'
                applications[single_app['-name']] = single_app.ConfigItem

        # no fucking clue how stray undefined is getting in, but it is
        # so it gots to die.
        delete applications['undefined']

        # Now we loop through all the application nodes and do a little
        # processing on them for better key/val pairs
        _.each applications, (app, key) =>
          applications[key] = @parse_application(app)

        # Attach the applications object to parent
        context[item['-name']]['applications'] = applications

      context

    # Parse an application context object into a nicer
    # key/val object (flatten that sucker a little)
    parse_application : (app) ->
      out = {}
      _.each app, (obj) =>
        if _.has obj, '-value'
          out[obj['-name']] = obj['-value'] 
        else if _.has obj, 'ConfigItem'
          out[obj['-name']] = obj.ConfigItem
      return out
      

    #### Get Context Map
    #
    # Parses @contexts and returns a collection of the
    # different application names contained within the
    # context. We use this to find out the proper names
    # of apps in @tentacles. Collection is keyed with
    # appname.
    #
    # Output:
    # 
    # {
    #   agencies : {
    #     businesses : {
    #       -name : "homewise",
    #       ConfigItem : { ... }
    #       label : "Agencies",
    #       type : "iframe"
    #     }
    #   }
    #   ...
    # }
    #
    # @param **data** _Object_ @contexts collection
    #
    get_context_map : (contexts) ->
      out = {}
      for context, applications of contexts
        for key, val of applications.applications
          out[key] = val
          out[key]['context'] = context
      out



    #### Get Contexts
    #
    # Return <contexts> from ixConfig doc
    #
    # @param **data** _Object_ ixConfig document
    #
    get_contexts : (data) ->
      list = @get_config_item(data, 'contexts')
      out = {}
      _.each list.ConfigItem, (item) ->
        out[item['-name']] = item.ConfigItem
      out


    #### Get Labels
    #
    # Iterate over ixConfig to get business names
    #
    # @param **data** _Object_ ixConfig node
    #
    get_labels : (data) ->
      out = {}
      labels = _.find data.ConfigItem, (item) ->
        item['-name'] == 'businesses'

      _.each labels.ConfigItem, (item) ->
        out[item['-name']] = item['-value']

      console.log out
      out

    #### Get ixAdmin
    #
    # Iterate over identity doc to extract ixAdmin node
    # of the correct environment
    #
    # @param **data** _Object_ identity node
    #
    get_ixadmin : (data) ->
      _.filter data.ApplicationSettings, (item) ->
        return item['-applicationName'] == 'ixadmin' && item['-environmentName'] == window.ICS360_ENV

    
    #### Get ConfigItem
    #
    # Iterate over ConfigItems looking for one with a specific name
    #
    # @param **collection** _Object_ object containing a ConfigItem array
    # @param **name** _Object_ name of ConfigItem to return
    #
    get_config_item : (collection, name) ->
      if collection? and collection.ConfigItem?
        _.find collection.ConfigItem, (item) ->
          item['-name'] == name


  MenuHelper