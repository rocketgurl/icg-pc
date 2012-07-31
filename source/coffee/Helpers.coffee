define [
  'jquery', 
  'underscore',
  'base64',
], ($, _, Base64) ->

  Helpers =

    # Create a string that's safe for use as an href or id
    id_safe : (string) ->
      reg = new RegExp '/\s*\W/gi'
      out = string.replace /\s*\W/gi, '_'
      if out is 'undefined' or out is undefined
        return null
      out


  Helpers