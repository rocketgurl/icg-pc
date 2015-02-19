define [
  'require',
  'jquery',
  'underscore',
  'mustache',
  'text!templates/tpl_main_nav.html',
  'text!templates/tpl_sub_nav_container.html',
  'text!templates/tpl_sub_nav_ul.html'
], (require, $, _, Mustache, tpl_main_nav, tpl_sub_nav_container, tpl_sub_nav_ul) ->

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
    # @param `identity` _Object_ ixDirectory document  
    # @param `ixconfig` _Object_ ixConfig document  
    #
    build_menu : (identity, ixconfig) ->

      @identity = identity.find('Identity')
      @ixconfig = ixconfig.find('ixConfig')

      # Get a nice object of business names from ixConfig
      @businesses = @ixconfig.find('ConfigItem[name=businesses]').first().children()
      business_names = {}
      @businesses.each (index, item) ->
        item = $(item)
        business_names[item.attr('name')] = item.attr('value')
      @businesses = business_names

      # These are the current possible contexts from ixConfig arranged
      # in an easy to access object by label (ex: cru, cruwic, etc)
      @contexts = @build_context_map(@ixconfig)

      # We need to generate an object that easily lets us map
      # different app names to their correct context
      @app_to_context_map = @get_context_map(@contexts)
      
      # Parse the tentacles from ixDirectory and build an
      # array of the valid ones
      @ixadmin = @identity.find("ApplicationSettings[applicationName=ixadmin][environmentName=#{window.ICS360_ENV}]")
      @tentacles = @get_tentacles(@ixadmin)

      # If we don't have any ixAdmin entries for this env or
      # tentacles then this person has no access to anything
      if @ixadmin.length == 0 || _.isEmpty @tentacles
        return false

      # Now assemble the building blocks into something usable
      return @compile_menu_collection(@businesses, @tentacles, @contexts)

    #### Generate Menu
    #
    # Consume the prepared object from @compile_menu_collection and
    # generate the required HTML tree to make the menu
    #
    # @param `data` _Object_ results of @compile_menu_collection
    #
    generate_menu : (data) ->
      # Generate main_nav
      main_nav = { main_nav : [] }
      sub_nav = ''

      # Loop throug objects
      for name, obj of data
        # Only generate a Main_Nav item if there are actual
        # contexts available to it
        if _.has(obj, 'contexts') and !_.isEmpty(obj.contexts)
            main_nav.main_nav.push {
              url      : name
              label    : obj.label
              business : name
            }

        # Sub nav
        submenu = { sub_nav_id : name, submenu : '' }
        for context, c_obj of obj.contexts
          out       = { sub_nav : [] }
          out.label = @check_length c_obj.label
          for index, a_obj of c_obj.apps
            out.sub_nav.push {
              url       : a_obj.app
              nav_label : a_obj.app_label
              business  : a_obj.business
              env       : a_obj.env
              context   : a_obj.context.context
            }

          submenu.submenu += Mustache.render tpl_sub_nav_ul, out
        sub_nav += Mustache.render tpl_sub_nav_container, submenu

      html =
        'main_nav' : Mustache.render tpl_main_nav, main_nav
        'sub_nav'  : sub_nav

    #### Compile Menu Collection
    #
    # Iterate over our building blocks and create a tree
    # of Businesses -> Contexts -> Applications
    #
    # @param `businesses` _Object_ businesses map  
    # @param `tentacles` _Object_ tentacle collection  
    # @param `contexts` _Object_ context collection  
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

    #### Get Tentacles
    #
    # Iterate over ixadmin node to extract tentacleLink nodes
    # and split into named pices for further processing
    #
    # @param `data` _Object_ ixAdmin node
    #
    get_tentacles : (data) ->
      data = data.find('tentacleLink')
      re = RegExp window.ICS360_ENV, "gi"

      # Array of tentacleLink path string of the correct env
      tentacles = []
      _.each data, (tentacle, index) ->
        path = $(tentacle).attr('path')
        if path != 'undefined' and path.match(re)
          # 8/16/12 - we are only getting Policy apps for now as per Lewisohn
          if path.match(/policies/gi)
            tentacles.push path
      

      # Take the tentacle path and process it, looking for valid
      # contexts (from ixConfig) and attempt to derive the correct
      # application name, etc.
      #
      # Example path: staging-fnic-rulesets_fnic  
      # Example expl: {env}-{business}-{app}
      #
      processed_tentacles = _.map tentacles, (val, key) =>
        pieces    = val.split '-'        
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
            business = _.pluck context.businesses, 'name'
          else if _.isObject context.businesses
            business = context.businesses['name']

        {
          'env'       : env
          'business'  : business
          'app'       : app
          'app_label' : app_label
          'context'   : context
          'tentacle'  : val
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
    #     contexts : {
    #       cru : {
    #          applications : {
    #            policies_cru : [],
    #            rulesets_cru : []
    #          },
    #          label : "CRU Surplus Residential and Commercial"
    #        },
    #        ...
    #      }
    # 
    # @param `data` _Object_ @contexts collection  
    #  
    build_context_map : (data) ->

      # Grab context nodes from XML
      contexts = @ixconfig.find('ConfigItem[name=contexts]').first().children()
      
      context_map = {}

      # Loop over nodes, building map
      contexts.each (index, context) =>
        $context = $(context)

        # Create a name object (ex: cruwic)
        item_label = $context.find('ConfigItem[name=label]').attr('value')

        # If this has an applications node then parse it
        if $context.find('ConfigItem[name=applications]')
          item_apps = $context.find('ConfigItem[name=applications]').children()

        # Create an Obj with the name of this context
        out = context_map[$context.attr('name')] = {}

        # Grab the label name if it exists
        if item_label?
          out.label = item_label

        applications = {}

        # Loop over the applications nodes and build properly
        # named objects to store the data in. Somtimes the application
        # node is a single object, sometimes and array of objects.
        item_apps.each (index, app) ->
          $app = $(app)
          app_out = applications[$app.attr('name')] = app

        # Now we loop through all the application nodes and do a little
        # processing on them for better key/val pairs
        for app_name, node of applications
          applications[app_name] = @parse_application node

        out['applications'] = applications
      context_map

    # Parse an application context object into a nicer
    # key/val object (flatten that sucker a little)
    parse_application : (app) ->
      out = {}
      app = $.fn.xml2json(app)
      _.each app.ConfigItem, (obj) =>
        if _.has obj, 'value'
          out[obj['name']] = obj['value'] 
        else if _.has obj, 'ConfigItem'
          out[obj['name']] = obj.ConfigItem
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
    #     {
    #       agencies : {
    #         businesses : {
    #           -name : "homewise",
    #           ConfigItem : { ... }
    #           label : "Agencies",
    #           type : "iframe"
    #         }
    #       }
    #       ...
    #     }
    # 
    # @param `data` _Object_ @contexts collection  
    #
    get_context_map : (contexts) ->
      out = {}
      for context, applications of contexts
        for key, val of applications.applications
          out[key] = val
          out[key]['context'] = context
      out

    # Shortens a string to 25 chars and adds ellipses
    #
    # @param `label` _String_ text  
    #  
    check_length : (label) ->
      if label.length > 25
        return label.substr(0, 25) + '&hellip;'
      label

    # ** constructs the workspace routes from the menu data **
    # Generates a list of routes we can pass to the Router
    # to launch a Workspace context (e.g. SageSure or FedNat)
    getWorkspaceRoutes : (data) ->
      routes = []
      _.each data, (item) ->
        _.each item.contexts, (context) ->
          _.each context.apps, (app) ->
            try
              routes.push "#workspace/#{app.env}/#{app.business}/#{app.context.context}/#{app.app}"
            catch err
              Muscula.errors.push err
      routes

  MenuHelper