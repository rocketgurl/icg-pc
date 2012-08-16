###
  Cookie handling

  Adapted from:  
  jQuery Cookie Plugin v1.2
  https://github.com/carhartl/jquery-cookie

  There is no reason to have cookie handling in a jQuery plugin. None.
  Also, the jQuery plugin had many issues with RequireJS and hooking into
  jQuery properly. So we just extract it out to a simple class.
###
define [], () ->

  class Cookie

    pluses   : /\+/g
    defaults : {}
    cookie   : null

    raw : (s) ->
      return s

    decoded : (s) ->
      decodeURIComponent(s.replace(@pluses, ' '))

    # Set a cookie with key -> val and an object of options
    set : (key, value, options) ->
      if value? and options?
        options = _.extend {}, @defaults, options
        if !value?
          options.expires = -1

        if typeof options.expires is 'number'
          days = options.expires
          t = options.expires = new Date()
          t.setDate t.getDate() + days

        value = String(value)

        return (document.cookie = [
          encodeURIComponent(key), '=', if options.raw then value else encodeURIComponent(value),
          if options.expires  then "; expires=#{options.expires.toUTCString()}" else '',
          if options.path     then "; path=#{options.path}" else '',
          if options.domain   then "; domain=#{options.domain}" else '',
          if options.secure   then "; secure" else ''
        ].join(''))

    # Get a cookie value by key
    get : (key) ->
      cookies = document.cookie.split('; ')
      for cookie in cookies
        if parts = cookie.split('=')
          if parts.shift() is key
            return @decoded(parts.join('='))

      return null

    # Kill the cookie
    remove : (key) ->
      if key?
        return document.cookie = "#{encodeURIComponent(key)}=; expires=Thu, 01 Jan 1970 00:00:01 GMT;"
      false
