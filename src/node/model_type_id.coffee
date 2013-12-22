###
  backbone-orm.js 0.5.4
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
###
_ = require 'underscore'
crypto = require 'crypto'

# @private
module.exports = class ModelTypeID

  constructor: ->
    @strict = true
    @ids = {}

  configure: (options={}) =>
    @strict = options.strict
    return @

  reset: =>
    @ids = {}
    return @

  modelID: (model_type) =>
    try url = _.result(model_type.prototype, 'url') catch e
    name_url = "#{url or ''}_#{model_type.model_name}"
    return crypto.createHash('md5').update(name_url).digest('hex')

  generate: (model_type) =>
    unless id = model_type.model_type_id # manual setting
      id = @modelID(model_type)
      if @strict and @ids[id] and @ids[id] isnt model_type
        throw new Error("Duplicate model name / url combination: #{model_type.model_name}, #{_.result(model_type.prototype, 'url')}. Set a unique model_name property on one of the conflicting models.")
    @ids[id] = model_type
    return id
