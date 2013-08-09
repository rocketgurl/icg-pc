###
  Underscore.policycentral
###
root = this

u = {}

# Deal with CommonJS and Node
if typeof exports != 'undefined'
  if typeof module != 'undefined' && module.exports
    exports = module.exports = u
  exports.u = u
else
  root.u = u

# Predicates
u.existy = (x) -> x != null
u.truthy = (x) -> (x != false) && this.existy(x)
u.nully  = (x) -> _.isNull(x) || _.isUndefined(x)

u.doWhen = (cond, action) ->
  if _.truthy(cond)
    return action.apply this, _.toArray arguments
  else
    return undefined

# Concatenate an array of strings with separator
u.joinStrings = (strings, separator) ->
  separator ?= ', '
  _.reduce strings, (memo, string) => _.join separator, memo, string

u.safeId = (string) ->
  _.doWhen _.existy(string), (string) =>
    string.replace /\s*\W/gi, '_'

u.deepClone = (p_object) ->
  JSON.parse(JSON.stringify(p_object))

# Export for AMD
if typeof define == 'function' && define.amd
  define('u_policycentral', ->
    u
  )