define [
  'jquery', 
  'underscore',
  'base64',
  'loader'
], ($, _, Base64, CanvasLoader) ->

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

    # Convenience method to create Canvas loader.
    # Returns loader object so it's easy to kill.
    loader : (id, diameter, color) ->
      cl = new window.CanvasLoader id
      cl.setColor color
      cl.setShape 'oval'
      cl.setDiameter diameter
      cl.setDensity 60
      cl.setFPS 24
      cl.show()
      return cl

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
      format = format || 'YYYY-MM-DD'
      moment(date).format(format)

    # Create an ISO timestamp
    makeTimestamp : ->
      moment(new Date()).format('YYYY-MM-DDTHH:mm:ss.sssZ')

    # Resize and element to the approximate height of the workspace
    #
    # @param `el` _HTML Element_ element to resize  
    # @param `offset` _Integer_ additional padding  
    #
    resize_element : (el, offset) ->
      offset = offset || 0
      el_height = Math.floor((($(window).height() - (184 + offset))/$(window).height())*100) + "%"
      el.css(
        'min-height' : el_height
        'height'     : $(window).height() - (184 + offset)
        )

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