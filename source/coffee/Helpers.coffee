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
      cl = new CanvasLoader id
      cl.setColor color
      cl.setShape 'oval'
      cl.setDiameter diameter
      cl.setDensity 60
      cl.setFPS 24
      cl.show()
      return cl

  Helpers