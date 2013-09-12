#pg = require('pg')
#conString = "postgres://jdpagano:1234@localhost/nodejs"
MongoClient = require('mongodb').MongoClient
format = require('util').format

connect_url = 'mongodb://127.0.0.1:27017/nodejs'

#MongoClient.connect connect_url, (err, db) ->
  #throw err if err
  #collection = db.collection('test_insert')
  #collection.insert {a:2}, (err, docs) ->
    #collection.count (err, count) ->
      #console.log(format("count = %s", count))

    #collection.find().toArray (err, results) ->
      #console.dir(results)
      #db.close()



Chat = ->

Chat.prototype.get_collection = (callback) ->
  MongoClient.connect connect_url, (err, db) ->
    throw err if err
    collection = db.collection('chat')
    callback(null, collection)
    db.close()



Chat.prototype.all = (callback) ->
  console.log "beginning the 'all' request for Users"
  @get_collection (err, collection) ->
    throw err if err
    callback(null, collection.find().toArray)


Chat.prototype.create = (obj, callback) ->
  @get_collection (err, collection) ->
    throw err if err
    @get_collection.insert obj, (err, docs) ->
      throw err if err
      callback(null, docs)


chat = new Chat()



console.log "starting script!"

chat.all (err, results) ->
  console.dir results

chat.create {name: "John Smith"}, (err, docs) ->
  console.dir docs

console.error "hitting end of script"

#Article.prototype.get_collection = (callback) ->
  #@db.collection 'articles', (error, article_collection) ->
    #console.info article_collection
    #if error then callback(error) else callback(null, article_collection)

#Article.prototype.find_all = (callback) ->
  #@get_collection (error, article_collection) ->
    #if error
      #callback(error)
    #else
      #article_collection.find().toArray (error, results) ->
        #if error then callback(error) else callback(null, results)

#Article.prototype.find_by_id = (id, callback) ->
  #@get_collection (error, article_collection) ->
    #if error
      #callback(error)
    #else
      #article_collection.findOne({_id:  new ObjectID(id)}, (error, result) ->
        #if error then callback(error) else callback(null, result)

#Article.prototype.save = (articles, callback) ->
  #@get_collection (error, article_collection) ->
    #if error
      #callback(error)
    #else
      #if typeof(articles.length) == undefined
        #articles = [articles]

      #for article in articles
        #article._id = article_counter++
        #article.created_at = new Date()
        #article.comments = [] unless article.comments

      #article_collection.insert articles, ->
        #callback(null, articles)


exports.Chat = Chat
