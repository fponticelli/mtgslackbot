package msb;

using thx.promise.Promise;
import npm.Arango;
import npm.arango.*;
using thx.Arrays;
using thx.Iterables;
using thx.Functions;
using thx.Maps;
using thx.Objects;
using thx.Strings;

import mtgx.json.Card;
import mtgx.json.Set;

class Db {
  static var MTG_DATABASE = "mtg";
  static var MTG_COLLECTIONS = ["refs", "sets", "cards"];

  var db : Database;
  public function new(connectionString : String) {
    this.db = Arango.connect(connectionString);
  }

  public function init() {
    return ensureDatabase()
      .append(ensureCollections);
    // return ensureCollections();
    // return .promise()
    //   .failure(function(e) {
    //     trace(e);
    //   });
    // return db.listCollections().promise()
    //   // .map(function(o) return o.collections)
    //   // .map(function(list) return list.filter(function(o) return !o.isSystem))
    //   .map(function(list) return list.map(haxe.Json.stringify.bind(_)));
    // // trace(db.collection.create("mtgcards"));
    // // return db.collection.create("mtgcards").promise();
  }

  function ensureDatabase() {
    return db.listDatabases()
      .promise()
      .flatMap(function(names) {
        if(names.contains(MTG_DATABASE))
          return Promise.nil;
        else
          return db.createDatabase(MTG_DATABASE).promise().nil();
      })
      .always(function() {
        db.useDatabase(MTG_DATABASE);
      });
  }

  function ensureCollections() {
    return db.listCollections()
      .promise()
      .flatMap(function(collections) {
        var names = collections.map.fn(_.name);
        var tocreate = MTG_COLLECTIONS.filter(function(collection) return !names.contains(collection));
        return Promise.sequence(tocreate.map(function(name) {
          return db.collection(name).create().promise();
        })).nil();
      });
  }

  public function uploadSets(sets : Map<String, Set>) {
    return Promise.nil
      .append(truncateCollection.bind("sets"))
      .append(truncateCollection.bind("cards"))
      .append(function() return Promise.sequence(sets.map(uploadSet)))
      .append(truncateCollection.bind("refs"))
      .append(createCardRefs);
  }

  public function uploadSet(cardSet : Set) {
    var cards = null == cardSet.cards ? [] : cardSet.cards;
    var record = {
      _key : cardSet.code,
      name : cardSet.name,
      code : cardSet.code,
      gathererCode : cardSet.gathererCode,
      oldCode : cardSet.oldCode,
      magicCardsInfoCode : cardSet.magicCardsInfoCode,
      releaseDate : cardSet.releaseDate,
      border : cardSet.border,
      type : cardSet.type,
      block : cardSet.block,
      onlineOnly : cardSet.onlineOnly,
      booster : cardSet.booster,
      cards : cards.map.fn(_.id)
    };
    var setCollection = db.collection("sets");
    return setCollection
      .save(record).promise()
      .append(function() {
        if(null == cardSet.releaseDate)
          trace('${cardSet.name} (${cards.length} cards)');
        else
          trace('${cardSet.name} - ${cardSet.releaseDate} (${cards.length} cards)');
        return Promise.sequence(cards.map(uploadSetCard.bind(_, cardSet.code)));
      });
  }

  public function truncateCollection(name : String)
    return db.collection(name).truncate().promise();

  public function createCardRefs() {
    return db.query('
      FOR card IN cards
        COLLECT cleanedName = card.cleanedName INTO g
        INSERT {
          _key : cleanedName,
          name: g[0].card.name,
          cards: (FOR c in g SORT c.card.multiverseid DESC RETURN c.card._key)
        } IN refs').promise();
  }

  public function uploadSetCard(card : Card, code : String) {
    var name = Api.cleanName(card.name).replace(" ", "_"),
        key = card.id; //'$code/$name';
    return db.collection("cards")
      .save(card.merge({
        _key : key,
        cleanedName : name,
        "set" : code
      })).promise();
  }
}
