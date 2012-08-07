define [
  'jquery', 
  'underscore',
  'base64',
], ($, _, Base64) ->

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

  Helpers