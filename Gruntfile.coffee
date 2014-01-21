_ = require 'underscore'
startsWith = (string, substring) -> string.lastIndexOf(substring, 0) is 0
splitTasks = (tasks)-> if !_.isString tasks then tasks else (_.filter tasks.split(/\s/), (v)-> v)
S = if process.platform is 'win32' then '\\' else '/'
nodeBin = "node_modules#{S}.bin#{S}"

module.exports = (grunt) ->
  pkg = grunt.file.readJSON('package.json')
  isNodeOnly = (d)-> d in [ 'stream', 'assert', 'url', 'util', 'querystring' ]
  gruntConfig =
    shell:
      mochaCmd: command: "#{nodeBin}mocha test/suite.coffee --compilers coffee:coffee-script --timeout 10000" # --reporter spec_UMD #options: execOptions: env: do -> process.env.NODE_ENV = 'test'; process.env # not working with --reporter spec_UMD, `stdout maxBuffer exceeded`
      options: {verbose: true, failOnError: true, stdout: true, stderr: true}

    zip: library:
      dest: 'backbone-orm.zip'
      router: (filepath) ->
        return "optional/#{filepath}" if startsWith(filepath, 'stream')
        return filepath['build/'.length..] if startsWith(filepath, 'build/')
        filepath
      src: ['build/backbone-orm*.js', 'stream*.js']

    clean: lib: ['lib'], build: ['build'], zip: ['*.zip']

    watch:
      UMD: files: ["src/**/*"],           tasks: ['UMD']
      dev: files: ["src/**/*"],           tasks: ['dev']
      build: files: ["src/**/*"],         tasks:   ['build']
      spec_UMD: files: ["test/**/*"],     tasks: ['urequire:spec_UMD']
      options: spawn: false

    mocha: AMD: src: [ "build/test/web/SpecRunner_unoptimized_AMD.html" ]

    urequire:
      _defaults:
        path: 'src'
        main: 'index'
        dependencies:
          exports: root: index: 'BackboneORM'
          node: [ 'node/**', '!', isNodeOnly ]
        resources: [ [ '+injectVERSION', ['index.js'], (m)-> m.beforeBody = "var VERSION = '#{pkg.version}';\n" ] ]
        template:
          name: 'UMDplain'
          banner: """
            /* backbone-orm.js #{pkg.version}
               Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
               License: MIT (http://www.opensource.org/licenses/mit-license.php)
               Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
            */
            """
        clean: true

      UMD: dstPath: "build/UMD"

      dev:
        dstPath: "build/backbone-orm"
        template: 'combined'

      min:
        dstPath: "build/backbone-orm-min.js"
        template: 'combined'
        optimize: true

      build:
        filez: ['**/*.coffee']
        dstPath: 'lib'
        resources: [
          [ '#justCoffeeCompile' ]
          [ '#injectVERSIONAsText', ['index.js'], (r)-> "var VERSION = '#{pkg.version}';\n" + r.converted ]
        ]

      libUMD: dstPath: "lib"

      spec_UMD:
        derive: []
        path: 'test'
        copy: /./
        template: 'UMDplain'
        dstPath: 'build/test'
        dependencies:
          node: [ '!', isNodeOnly ]
          replace: '../UMD': '../lib|'

  grunt.registerTask cmd, splitTasks "#{task}:#{cmd}" for cmd of gruntConfig[task] for task in ['shell', 'urequire']
  grunt.registerTask shortCut, splitTasks tasks for shortCut, tasks of {
    default:         'prepublish'
    prepublish:      'dev min zip:library'
    all:             "UMD dev min"
    test:            "build mochaCmd"
    test_UMD:        "libUMD mochaCmd"
    test_web:        "UMD spec_UMD mocha"
    test_all:        "test_UMD test_web test"
  }

  for task of pkg.devDependencies
    grunt.loadNpmTasks task if startsWith(task, 'grunt-') and task isnt 'grunt-cli'

  grunt.initConfig gruntConfig