define [
  'jquery',
  'underscore',
  'base64',
  'loader',
  'favicon'
], ($, _, Base64, CanvasLoader, Favicon) ->

  Helpers =

    # Create a string that's safe for use as an href or id
    id_safe : (string) ->
      if !string?
        return null

      reg = new RegExp '/\s*\W/gi'
      out = string.replace /\s*\W/gi, '_'

      if out is 'undefined' or out is undefined
        return null
      out

    # Capitalize the first letter in a string
    uc_first : (string) ->
      return string.substr(0,1).toUpperCase() + string.substr(1)

    # Unserialize a url-ready string into an object
    unserialize : (string) ->
      out = {}
      params = string.split '/'
      for value in params
        [k, v] = value.split ':'
        if k? && v?
          out[k] = decodeURI(v)
      out

    # Serialize an object to a URL ready string
    serialize : (object) ->
      serialized = ''
      for key, value of object
        serialized += "/#{key}:#{encodeURI(value)}"
      serialized

    deparam : (query) ->
      params = {}
      decode = (val) ->
        if val?
          decodeURIComponent val
        else
          null

      # remove preceding non-querystring,
      # correct spaces, and split into pairs
      query = query
        .substring(query.indexOf('?') + 1)
        .replace(/\+/g, ' ')
        .split('&')

      _.each query, (pair) ->
        pair = pair.split '='
        key = decode(pair[0])
        val = decode(pair[1])
        params[key] = val if key

      params

    # Convenience method to create Canvas loader.
    # Returns loader object so it's easy to kill.
    loader : (id, diameter, color) ->
      cl = new window.CanvasLoader id
      cl.setColor color
      cl.setShape 'oval'
      cl.setDiameter diameter
      cl.setDensity 60
      cl.setFPS 30
      cl.setRange 0.9
      cl.show()
      return cl

    # Simple start and stop methods for animating favicon
    # loading icon. 250ms seems to be the smallest interval
    # we can use without getting choppy
    faviconLoader : ->
      originalTitle = document.title
      favicon = new Favicon([
        '/ico/gear-0.png'
        '/ico/gear-1.png'
        '/ico/gear-2.png'
      ], 250)
      return {
        start : (optDocTitle) -> favicon.animate(optDocTitle)
        stop : -> favicon.set('/favicon.ico', originalTitle)
      }

    # When you need to display a prettier
    # set of values than the given data
    prettyMap : (value, valueMap={}, defaultVal='') ->
      valueMap[value] || value || defaultVal

    # coerce a string like 'true' to it's proper Boolean type
    strToBool : (value) ->
      if _.isString value
        value.toLowerCase() is 'true'
      else if _.isBoolean value
        value
      else
        false

    # Simple wrapper on setTimeout
    callback_delay : (ms, func) =>
      setTimeout func, ms

    # Return a random number tween min and max
    random : (min, max) ->
      Math.floor(Math.random() * (max - min + 1)) + min

    # Create a Base64 digest to use in Basic Auth
    createDigest : (username, password) ->
      Base64.encode "#{username}:#{password}"

    # Convert an XML object to a string
    XMLToString : (oXML) ->
      if (window.ActiveXObject)
        oXML.xml;
      else
        (new XMLSerializer()).serializeToString(oXML);

    # Create an XML object from a string using the browser's DOMParser
    XMLFromString : (sXML) ->
      if (window.ActiveXObject)
        oXML = new ActiveXObject("Microsoft.XMLDOM")
        oXML.loadXML(sXML)
        oXML
      else
        (new DOMParser()).parseFromString(sXML, "text/xml")

    # Because of the quirky way the xml is parsed to json
    # Possible data types returned can be unreliable, especially for
    # Arrays of items. This is an attempt to sanitize the results
    sanitizeNodeArray : (node) ->
      items = node || []
      unless _.isArray items
        items = [items]
      items

    # Determine if a number is an **integer**. Will return false on floats,
    # NaN, booleans, etc.
    # http://stackoverflow.com/questions/3885817/how-to-check-if-a-number-is-float-or-integer
    #
    # @param `n` _Mixed_
    # @return _Boolean_
    #
    isInt : (n) ->
      typeof n == 'number' && n % 1 == 0

    # Coerce form input into a number, return zero on NaN
    #
    # @param `n` _Mixed_
    # @return _Number_
    #
    toNum : (n) ->
      n = Math.abs(n || 0)
      if _.isNaN(n)
        return 0
      else
        n

    # Format a number as float with 2 decimal places (ex: 5.25)
    # NaN and non-numbers will return 0.00 - NaN is technically a number so
    # we need to check for it upfront
    #
    # @param `n` _Number_
    # @return _String_ (Float)
    #
    formatMoney : (n) ->
      n = parseFloat n # convert a string val from form into a Number
      if _.isNaN n
        '0.00'
      else
        n.toFixed 2

    # Add commas to numbers
    formatLocaleNum : (n) ->
      n = parseFloat n
      if _.isNaN n
        '0'
      else
        n.toLocaleString()

    # Some date strings we'll be dealing with are formatted with a full
    # timestamp like: "2011-01-15T23:00:00-04:00". The time, after the "T"
    # can sometimes cause weird rounding issues with the day. To safegaurd
    # against it, we'll just remove the "T" and everything after it.
    #
    # @param `date` _String_ A date string
    # @param `format` _String_ (optional) A date format string
    # @return _String_ An ISO formatted date string
    #
    stripTimeFromDate : (date, format) ->
      format = format ? null
      clean  = date
      t      = date.indexOf('T')
      if t > -1
        clean = clean.substring(0, t)
      @formatDate clean, format

    # Format a date, defaulting to ISO format
    #
    # @param `date` _String_ A date string
    # @param `format` _String_ A date format string
    # @return _String_
    #
    formatDate : (date, format) ->
      format = format ? 'YYYY-MM-DD'
      date && moment(date).format(format)

    # Create an ISO timestamp
    makeTimestamp : ->
      moment(new Date()).format('YYYY-MM-DDTHH:mm:ss.sssZ')


    # Generate GUID, used as a key in localstorage or file upload or whathaveyou
    createGUID : ->
      # Generate primitive for GUID
      s4 = -> (((1+Math.random())*0x10000)|0).toString(16).substring(1)

      "#{s4()+s4()}-#{s4()}-#{s4()}-#{s4()}-#{s4()+s4()+s4()}".toUpperCase()

    # Resize an element to the approximate height of the workspace
    #
    # @param `el` _HTML Element_ element to resize
    # @param `offset` _Integer_ additional padding
    #
    resize_element : (el, offset, scroll) ->
      offset = offset || 0
      el_height = Math.floor((($(window).height() - (184 + offset))/$(window).height())*100) + "%"
      el.css(
        'min-height' : el_height
        'height'     : $(window).height() - (184 + offset)
        )

      if scroll
        el.css('overflow', 'auto')
      else
        el.css('overflow', 'none')

    # Resize workspace to include the size of the element
    #
    # @param `el` _HTML Element_ element to compare workspace to
    # @param `workspace` _HTML Element_ element to resize
    #
    resize_workspace : (el, workspace) ->
      window_height    = Math.floor($(window).height())
      el_height        = Math.floor(el.height())
      workspace_height = Math.floor(workspace.height())
      offset           = Math.abs(el_height - window_height) + 100
      workspace.height(el_height + 100)


    # Take a name and properly capitalize it
    #
    # @param `name` _String_
    # @returns _String_
    #
    properName : (name) ->
      name = @parseNamePrefix(name.toLowerCase())
      name = @parseNameSuffix(name)
      name

    # Properly capitalize complex names (ex: MacGuffin, O'Shea)
    #
    # @param `name` _String_
    # @returns _String_
    #
    parseNamePrefix : (name) ->
      prefixes = ['mac', 'mc', 'van', "d'", "o'"]
      result = _.find prefixes, (prefix) ->
        re = RegExp(prefix, "i")
        re.test(name)

      if result != undefined
        name    = name.split(result)
        name[0] = result
        name = _.map(name, (fragment) ->
            _.titleize(fragment)
          )
        name = name.join('')
      else
        name = _.titleize name

      name

    # Capitalize the suffixes
    #
    # @param `name` _String_
    # @returns _String_
    #
    parseNameSuffix : (name) ->
      suffixes = ['jr', 'snr', 'phd', 'esq', 'cpa']
      result = _.find suffixes, (suffix) ->
        re = RegExp(suffix, "i")
        re.test(name)

      if result != undefined
        re   = RegExp(result, "i")
        name = name.replace(re, _.titleize(result))

      name

    # Super simple function to concat two strings with a seperator.
    #
    # @param `a` _String_
    # @param `b` _String_
    # @param `separator` _String_
    # @returns _String_
    #
    concatStrings : (a, b, separator) ->
      separator = separator ? ', '
      out = " "
      if a
        out = _.trim("#{a}")
      if b
        out = _.trim("#{out}#{separator}#{b}")
      out

  Helpers