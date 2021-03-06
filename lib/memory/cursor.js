// Generated by CoffeeScript 1.6.3
/*
  backbone-orm.js 0.5.4
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
*/


(function() {
  var Cursor, IS_MATCH_FNS, IS_MATCH_OPERATORS, JSONUtils, MemoryCursor, Queue, Utils, inflection, moment, _, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  _ = require('underscore');

  moment = require('moment');

  inflection = require('inflection');

  Queue = require('../queue');

  Utils = require('../utils');

  JSONUtils = require('../json_utils');

  Cursor = require('../cursor');

  IS_MATCH_FNS = {
    $ne: function(mv, tv) {
      return !_.isEqual(mv, tv);
    },
    $lt: function(mv, tv) {
      if (_.isNull(tv)) {
        throw Error('Cannot compare to null');
      }
      return (_.isDate(tv) ? moment(mv).isBefore(tv) : mv < tv);
    },
    $lte: function(mv, tv) {
      var mvm;
      if (_.isNull(tv)) {
        throw Error('Cannot compare to null');
      }
      if (_.isDate(tv)) {
        mvm = moment(mv);
        return mvm.isBefore(tv) || mvm.isSame(tv);
      } else {
        return (mv < tv) || _.isEqual(mv, tv);
      }
    },
    $gt: function(mv, tv) {
      if (_.isNull(tv)) {
        throw Error('Cannot compare to null');
      }
      return (_.isDate(tv) ? moment(mv).isAfter(tv) : mv > tv);
    },
    $gte: function(mv, tv) {
      var mvm;
      if (_.isNull(tv)) {
        throw Error('Cannot compare to null');
      }
      if (_.isDate(tv)) {
        mvm = moment(mv);
        return mvm.isAfter(tv) || mvm.isSame(tv);
      } else {
        return (mv > tv) || _.isEqual(mv, tv);
      }
    }
  };

  IS_MATCH_OPERATORS = _.keys(IS_MATCH_FNS);

  module.exports = MemoryCursor = (function(_super) {
    __extends(MemoryCursor, _super);

    function MemoryCursor() {
      _ref = MemoryCursor.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    MemoryCursor.prototype.queryToJSON = function(callback) {
      var exists,
        _this = this;
      if (this.hasCursorQuery('$zero')) {
        return callback(null, this.hasCursorQuery('$one') ? null : []);
      }
      exists = this.hasCursorQuery('$exists');
      return this.buildFindQuery(function(err, find_query) {
        var json, keys, queue;
        if (err) {
          return callback(err);
        }
        json = [];
        keys = _.keys(find_query);
        queue = new Queue(1);
        queue.defer(function(callback) {
          var find_queue, id, ins, ins_size, key, model_json, nins, nins_size, value, _fn, _ref1, _ref2, _ref3, _ref4, _ref5;
          _ref1 = [{}, {}], ins = _ref1[0], nins = _ref1[1];
          for (key in find_query) {
            value = find_query[key];
            if (value != null ? value.$in : void 0) {
              delete find_query[key];
              ins[key] = value.$in;
            }
            if (value != null ? value.$nin : void 0) {
              delete find_query[key];
              nins[key] = value.$nin;
            }
          }
          _ref2 = [_.size(ins), _.size(nins)], ins_size = _ref2[0], nins_size = _ref2[1];
          if (keys.length || ins_size || nins_size) {
            if (_this._cursor.$ids) {
              _ref3 = _this.store;
              for (id in _ref3) {
                model_json = _ref3[id];
                if (_.contains(_this._cursor.$ids, id) && _.isEqual(_.pick(model_json, keys), find_query)) {
                  json.push(JSONUtils.deepClone(model_json));
                }
              }
              return callback();
            } else {
              find_queue = new Queue();
              _ref4 = _this.store;
              _fn = function(model_json) {
                return find_queue.defer(function(callback) {
                  var find_keys, next;
                  find_keys = _.keys(find_query);
                  next = function(err, is_match) {
                    if (err) {
                      return callback(err);
                    }
                    if (!is_match) {
                      return callback();
                    }
                    if (!find_keys.length || (exists && (keys.length !== find_keys.length))) {
                      json.push(JSONUtils.deepClone(model_json));
                      return callback();
                    }
                    return _this._valueIsMatch(find_query, find_keys.pop(), model_json, next);
                  };
                  return next(null, true);
                });
              };
              for (id in _ref4) {
                model_json = _ref4[id];
                _fn(model_json);
              }
              return find_queue.await(function(err) {
                if (err) {
                  return callback(err);
                }
                if (ins_size) {
                  json = _.filter(json, function(model_json) {
                    var values, _ref5;
                    for (key in ins) {
                      values = ins[key];
                      if (_ref5 = model_json[key], __indexOf.call(values, _ref5) >= 0) {
                        return true;
                      }
                    }
                  });
                }
                if (nins_size) {
                  json = _.filter(json, function(model_json) {
                    var values, _ref5;
                    for (key in nins) {
                      values = nins[key];
                      if (_ref5 = model_json[key], __indexOf.call(values, _ref5) < 0) {
                        return true;
                      }
                    }
                  });
                }
                return callback();
              });
            }
          } else {
            if (_this._cursor.$ids) {
              _ref5 = _this.store;
              for (id in _ref5) {
                model_json = _ref5[id];
                if (_.contains(_this._cursor.$ids, id)) {
                  json.push(JSONUtils.deepClone(model_json));
                }
              }
            } else {
              json = (function() {
                var _ref6, _results;
                _ref6 = this.store;
                _results = [];
                for (id in _ref6) {
                  model_json = _ref6[id];
                  _results.push(JSONUtils.deepClone(model_json));
                }
                return _results;
              }).call(_this);
            }
            return callback();
          }
        });
        if (!exists) {
          queue.defer(function(callback) {
            var $sort_fields, number;
            if (_this._cursor.$sort) {
              $sort_fields = _.isArray(_this._cursor.$sort) ? _this._cursor.$sort : [_this._cursor.$sort];
              json.sort(function(model, next_model) {
                return Utils.jsonFieldCompare(model, next_model, $sort_fields);
              });
            }
            if (_this._cursor.$offset) {
              number = json.length - _this._cursor.$offset;
              if (number < 0) {
                number = 0;
              }
              json = number ? json.slice(_this._cursor.$offset, _this._cursor.$offset + number) : [];
            }
            if (_this._cursor.$one) {
              json = json.length ? [json[0]] : [];
            } else if (_this._cursor.$limit) {
              json = json.splice(0, Math.min(json.length, _this._cursor.$limit));
            }
            return callback();
          });
          queue.defer(function(callback) {
            return _this.fetchIncludes(json, callback);
          });
        }
        queue.await(function() {
          var count_cursor;
          if (_this.hasCursorQuery('$count')) {
            return callback(null, (_.isArray(json) ? json.length : (json ? 1 : 0)));
          }
          if (exists) {
            return callback(null, (_.isArray(json) ? !!json.length : json));
          }
          json = _this.selectResults(json);
          if (_this.hasCursorQuery('$page')) {
            count_cursor = new MemoryCursor(_this._find, _.extend(_.pick(_this, ['model_type', 'store'])));
            return count_cursor.count(function(err, count) {
              return callback(null, {
                offset: _this._cursor.$offset || 0,
                total_rows: count,
                rows: json
              });
            });
          } else {
            return callback(null, json);
          }
        });
      });
    };

    MemoryCursor.prototype.buildFindQuery = function(callback) {
      var find_query, key, queue, relation_key, reverse_relation, value, value_key, _fn, _ref1, _ref2,
        _this = this;
      queue = new Queue();
      find_query = {};
      _ref1 = this._find;
      _fn = function(relation_key, value_key, value) {
        return queue.defer(function(callback) {
          var related_query, relation;
          if (!(relation = _this.model_type.relation(relation_key))) {
            find_query[key] = value;
            return callback();
          }
          if (!relation.join_table && (value_key === 'id')) {
            find_query[relation.foreign_key] = value;
            return callback();
          } else if (relation.join_table || (relation.type === 'belongsTo')) {
            (related_query = {
              $values: 'id'
            })[value_key] = value;
            return relation.reverse_relation.model_type.cursor(related_query).toJSON(function(err, related_ids) {
              var join_query;
              if (err) {
                return callback(err);
              }
              if (relation.join_table) {
                (join_query = {})[relation.reverse_relation.join_key] = {
                  $in: _.compact(related_ids)
                };
                join_query.$values = relation.foreign_key;
                return relation.join_table.cursor(join_query).toJSON(function(err, model_ids) {
                  if (err) {
                    return callback(err);
                  }
                  find_query.id = {
                    $in: _.compact(model_ids)
                  };
                  return callback();
                });
              } else {
                find_query[relation.foreign_key] = {
                  $in: _.compact(related_ids)
                };
                return callback();
              }
            });
          } else {
            (related_query = {})[value_key] = value;
            related_query.$values = relation.foreign_key;
            return relation.reverse_model_type.cursor(related_query).toJSON(function(err, model_ids) {
              if (err) {
                return callback(err);
              }
              find_query.id = {
                $in: _.compact(model_ids)
              };
              return callback();
            });
          }
        });
      };
      for (key in _ref1) {
        value = _ref1[key];
        if (key.indexOf('.') < 0) {
          if (!(reverse_relation = this.model_type.reverseRelation(key))) {
            find_query[key] = value;
            continue;
          }
          if (!reverse_relation.embed && !reverse_relation.join_table) {
            find_query[key] = value;
            continue;
          }
          (function(key, value, reverse_relation) {
            return queue.defer(function(callback) {
              var related_query;
              if (reverse_relation.embed) {
                throw Error("Embedded find is not yet supported. @_find: " + (Utils.inspect(_this._find)));
                (related_query = {}).id = value;
                return reverse_relation.model_type.cursor(related_query).toJSON(function(err, models_json) {
                  if (err) {
                    return callback(err);
                  }
                  find_query._json = _.map(models_json, function(test) {
                    return test[reverse_relation.key];
                  });
                  return callback();
                });
              } else {
                (related_query = {})[key] = value;
                related_query.$values = reverse_relation.reverse_relation.join_key;
                return reverse_relation.join_table.cursor(related_query).toJSON(function(err, model_ids) {
                  if (err) {
                    return callback(err);
                  }
                  find_query.id = {
                    $in: model_ids
                  };
                  return callback();
                });
              }
            });
          })(key, value, reverse_relation);
          continue;
        }
        _ref2 = key.split('.'), relation_key = _ref2[0], value_key = _ref2[1];
        if (this.model_type.relationIsEmbedded(relation_key)) {
          find_query[key] = value;
          continue;
        }
        _fn(relation_key, value_key, value);
      }
      return queue.await(function(err) {
        return callback(err, find_query);
      });
    };

    MemoryCursor.prototype.fetchIncludes = function(json, callback) {
      var include_keys, key, load_queue, model_json, relation, _fn, _i, _j, _len, _len1,
        _this = this;
      if (!this._cursor.$include) {
        return callback();
      }
      load_queue = new Queue(1);
      include_keys = _.isArray(this._cursor.$include) ? this._cursor.$include : [this._cursor.$include];
      for (_i = 0, _len = include_keys.length; _i < _len; _i++) {
        key = include_keys[_i];
        if (this.model_type.relationIsEmbedded(key)) {
          continue;
        }
        if (!(relation = this.model_type.relation(key))) {
          return callback(new Error("Included relation '" + key + "' is not a relation"));
        }
        _fn = function(key, model_json) {
          return load_queue.defer(function(callback) {
            return relation.cursor(model_json, key).toJSON(function(err, related_json) {
              if (err) {
                return calback(err);
              }
              delete model_json[relation.foriegn_key];
              model_json[key] = related_json;
              return callback();
            });
          });
        };
        for (_j = 0, _len1 = json.length; _j < _len1; _j++) {
          model_json = json[_j];
          _fn(key, model_json);
        }
      }
      return load_queue.await(callback);
    };

    MemoryCursor.prototype._valueIsMatch = function(find_query, key_path, model_json, callback) {
      var key_components, model_type, next,
        _this = this;
      key_components = key_path.split('.');
      model_type = this.model_type;
      next = function(err, models_json) {
        var find_value, is_match, key, model_value, operator, relation, was_handled, _i, _j, _len, _len1;
        if (err) {
          return callback(err);
        }
        key = key_components.shift();
        if (key === 'id') {
          key = model_type.prototype.idAttribute;
        }
        if (!key_components.length) {
          was_handled = false;
          find_value = find_query[key_path];
          if (!_.isArray(models_json)) {
            models_json = [models_json];
          }
          for (_i = 0, _len = models_json.length; _i < _len; _i++) {
            model_json = models_json[_i];
            model_value = model_json[key];
            if (_.isObject(find_value)) {
              for (_j = 0, _len1 = IS_MATCH_OPERATORS.length; _j < _len1; _j++) {
                operator = IS_MATCH_OPERATORS[_j];
                if (!(find_value.hasOwnProperty(operator))) {
                  continue;
                }
                was_handled = true;
                if (!(is_match = IS_MATCH_FNS[operator](model_value, find_value[operator]))) {
                  break;
                }
              }
            }
            if (was_handled) {
              if (is_match) {
                return callback(null, is_match);
              }
            } else if (is_match = _.isEqual(model_value, find_value)) {
              return callback(null, is_match);
            }
          }
          return callback(null, false);
        }
        if ((relation = model_type.relation(key)) && !relation.embed) {
          return relation.cursor(model_json, key).toJSON(next);
        }
        return next(null, model_json[key]);
      };
      return next(null, model_json);
    };

    return MemoryCursor;

  })(Cursor);

}).call(this);
