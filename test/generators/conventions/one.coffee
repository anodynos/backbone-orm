util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require '../../../lib/queue'

ModelCache = require('../../../lib/cache/singletons').ModelCache
QueryCache = require('../../../lib/cache/singletons').QueryCache
Fabricator = require '../../fabricator'
Utils = require '../../../lib/utils'
JSONUtils = require '../../../lib/json_utils'

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: BASE_SCHEMA
    sync: SYNC(Flat)

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    schema: _.defaults({
      owner: -> ['belongs_to', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Reverse)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    schema: _.defaults({
      flat: -> ['BelongsTo', Flat, embed: options.embed]
      reverse: -> ['has_one', Reverse]
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  describe "One (cache: #{options.cache}, query_cache: #{options.query_cache}, embed: #{options.embed})", ->

    before (done) -> return done() unless options.before; options.before([Flat, Reverse, Owner], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      MODELS = {}
      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure model cache
      queue.defer (callback) -> QueryCache.configure({enabled: !!options.query_cache, verbose: false}).reset(callback) # configure query cache

      # destroy all
      queue.defer (callback) -> Utils.resetSchemas [Flat, Reverse, Owner], callback

      # create all
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Reverse, BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owner_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err))

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        reverses = MODELS.reverse.slice()
        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.save {flat: MODELS.flat.pop(), reverse: reverses.pop()}, callback

        save_queue.await callback

      queue.await done

#    # TODO: delay the returning of memory models related models to test lazy loading properly
#    it 'Fetches a relation from the store if not present', (done) ->
#      Owner.findOne (err, test_model) ->
#        assert.ok(!err, "No errors: #{err}")
#        assert.ok(test_model, 'found model')
#
#        fetched_owner = new Owner({id: test_model.id})
#        fetched_owner.fetch (err) ->
#          assert.ok(!err, "No errors: #{err}")
#          delete fetched_owner.attributes.reverse
#
#          fetched_owner.get 'reverse', (err, reverse) ->
#            assert.ok(!err, "No errors: #{err}")
#            assert.ok(reverse, 'loaded the model lazily')
#            assert.equal(reverse.get('owner_id'), test_model.id)
#            done()
#  #          assert.equal(reverse, null, 'has not loaded the model initially')

    it 'Has an id loaded for a belongsTo and not for a hasOne relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        assert.ok(test_model.get('flat_id'), 'belongsTo id is loaded')
  #        assert.ok(!test_model.get('reverse_id'), 'hasOne id is not loaded')
        done()

    it 'Handles a get query for a belongsTo relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'flat', (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(flat, 'found related model')
          if test_model.relationIsEmbedded('flat')
            assert.deepEqual(test_model.toJSON().flat, flat.toJSON(), "Serialized embed. Expected: #{util.inspect(test_model.toJSON().flat)}. Actual: #{util.inspect(flat.toJSON())}")
          else
            assert.deepEqual(test_model.toJSON().flat_id, flat.id, "Serialized id only. Expected: #{test_model.toJSON().flat_id}. Actual: #{flat.id}")
          assert.equal(test_model.get('flat_id'), flat.id, "\nExpected: #{test_model.get('flat_id')}\nActual: #{flat.id}")
          done()

    it 'Can retrieve an id for a hasOne relation via async virtual method', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        test_model.get 'reverse_id', (err, id) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(id, 'found id')
          done()

    it 'Handles a get query for a hasOne relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'reverse', (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found related model')
          assert.equal(test_model.id, reverse.get('owner_id'), "\nExpected: #{test_model.id}\nActual: #{reverse.get('owner_id')}")
          assert.equal(test_model.id, reverse.toJSON().owner_id, "\nReverse toJSON has an owner_id. Expected: #{test_model.id}\nActual: #{reverse.toJSON().owner_id}")
          if test_model.relationIsEmbedded('reverse')
            assert.deepEqual(test_model.toJSON().reverse, reverse.toJSON(), "Serialized embed. Expected: #{util.inspect(test_model.toJSON().reverse)}. Actual: #{util.inspect(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_id, 'No reverese_id in owner json')
          done()

    it 'Handles a get query for a hasOne and belongsTo two sided relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'reverse', (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found related model')
          assert.equal(test_model.id, reverse.get('owner_id'), "\nExpected: #{test_model.id}\nActual: #{reverse.get('owner_id')}")
          assert.equal(test_model.id, reverse.toJSON().owner_id, "\nReverse toJSON has an owner_id. Expected: #{test_model.id}\nActual: #{reverse.toJSON().owner_id}")
          if test_model.relationIsEmbedded('reverse')
            assert.deepEqual(test_model.toJSON().reverse, reverse.toJSON(), "Serialized embed. Expected: #{util.inspect(test_model.toJSON().reverse)}. Actual: #{util.inspect(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_id, 'No reverese_id in owner json')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'found original model')
            assert.deepEqual(reverse.toJSON().owner_id, owner.id, "Serialized id only. Expected: #{reverse.toJSON().owner_id}. Actual: #{owner.id}")

            if Owner.cache
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "\nExpected: #{util.inspect(test_model.toJSON())}\nActual: #{util.inspect(owner.toJSON())}")
            else
              assert.equal(test_model.id, owner.id, "\nExpected: #{test_model.id}\nActual: #{owner.id}")
            done()


    it 'Appends json for a related model', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        JSONUtils.renderRelated test_model, 'reverse', ['id', 'created_at'], (err, related_json) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(related_json.id, "reverse has an id")
          assert.ok(related_json.created_at, "reverse has a created_at")
          assert.ok(!related_json.updated_at, "reverse doesn't have updated_at")

          JSONUtils.renderRelated test_model, 'flat', ['id', 'created_at'], (err, related_json) ->
            assert.ok(!err, "No errors: #{err}")

            assert.ok(related_json.id, "flat has an id")
#            assert.ok(related_json.created_at, "flat has a created_at")
            assert.ok(!related_json.updated_at, "flat doesn't have updated_at")
            done()
