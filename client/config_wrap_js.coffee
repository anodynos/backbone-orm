module.exports =

  library_license: """
    /*
      backbone-orm.js 0.0.1
      Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
      License: MIT (http://www.opensource.org/licenses/mit-license.php)
      Dependencies: Backbone.js and Underscore.js.
    */
    """

  library_start: """
    (function() {
    """

  library_end: """
    if (typeof exports == 'object') {
      module.exports = require('src/index');
    } else if (typeof define == 'function' && define.amd) {
      define('bborm', ['underscore', 'backbone'], function(){ return require('src/index'); });
    } else {
      this['bborm'] = require('src/index');
    }
    }).call(this);
    """

  vendor_start: """
    (function() {
    (function(/*! Brunch !*/) {
      'use strict';

      var globals = typeof window !== 'undefined' ? window : global;
      if (typeof globals.require === 'function') return;

      var modules = {};
      var cache = {};

      var has = function(object, name) {
        return ({}).hasOwnProperty.call(object, name);
      };

      var expand = function(root, name) {
        var results = [], parts, part;
        if (/^\\.\\.?(\\/|$)/.test(name)) {
          parts = [root, name].join('/').split('/');
        } else {
          parts = name.split('/');
        }
        for (var i = 0, length = parts.length; i < length; i++) {
          part = parts[i];
          if (part === '..') {
            results.pop();
          } else if (part !== '.' && part !== '') {
            results.push(part);
          }
        }
        return results.join('/');
      };

      var dirname = function(path) {
        return path.split('/').slice(0, -1).join('/');
      };

      var localRequire = function(path) {
        return function(name) {
          var dir = dirname(path);
          var absolute = expand(dir, name);
          return globals.require(absolute, path);
        };
      };

      var initModule = function(name, definition) {
        var module = {id: name, exports: {}};
        cache[name] = module;
        definition(module.exports, localRequire(name), module);
        return module.exports;
      };

      var require = function(name, loaderPath) {
        var path = expand(name, '.');
        if (loaderPath == null) loaderPath = '/';

        if (has(cache, path)) return cache[path].exports;
        if (has(modules, path)) return initModule(path, modules[path]);

        var dirIndex = expand(path, './index');
        if (has(cache, dirIndex)) return cache[dirIndex].exports;
        if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

        throw new Error('Cannot find module "' + name + '" from '+ '"' + loaderPath + '"');
      };

      var define = function(bundle, fn) {
        if (typeof bundle === 'object') {
          for (var key in bundle) {
            if (has(bundle, key)) {
              modules[key] = bundle[key];
            }
          }
        } else {
          modules[bundle] = fn;
        }
      };

      var list = function() {
        var result = [];
        for (var item in modules) {
          if (has(modules, item)) {
            result.push(item);
          }
        }
        return result;
      };

      globals.require = require;
      globals.require.define = define;
      globals.require.register = define;
      globals.require.list = list;
      globals.require.brunch = true;
    })();
    """

  vendor_end: """
      var MODULES, module_name, _fn, _i, _len;
      MODULES = ['underscore', 'backbone', 'inflection', 'moment'];

      _fn = function(module_name) {
        window.require.register(module_name, function(exports, brunch_require, module) {
          return module.exports = require.call(this, module_name);
        });
        return window.require.register("" + module_name + "/index", function(exports, brunch_require, module) {
          return module.exports = require.call(this, module_name);
        });
      };
      for (_i = 0, _len = MODULES.length; _i < _len; _i++) { _fn(MODULES[_i]);}
    }).call(this);
    """