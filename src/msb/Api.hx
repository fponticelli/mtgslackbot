package msb;

import thx.Objects;
import haxe.Json;
import thx.Error;
import thx.promise.Promise;
import thx.text.Diactrics;
using thx.Arrays;
using thx.Ints;
using thx.Iterators;
using thx.Maps;
using thx.Objects;
using thx.Strings;
import js.node.Fs;

import mtgx.json.Card;
import mtgx.json.Set;

class Api {
  var setsByCode : Map<String, Set>;
  var cardsByName : Map<String, Card>;
  var cards : Array<NormalizedCard>;
  var sets : Array<Set>;
  public function new() {
    setsByCode = new Map();
    cardsByName = new Map();
    cards = [];
    sets = [];
  }

  public function queryCards(query : Query) {
    return Promise.value(Queries.query(cards, query));
  }

  public function count() : Promise<Int>
    return Promise.value(cards.length);

  public function queryCard(name : String) {
    var cleanedName = cleanName(name),
        card = cardsByName.get(cleanedName);
    return null != card ?
      Promise.value(card) :
      Promise.error(new Error('Card not found "$name"')); // TODO replace with proper error type
  }

  public function loadSetsFromFileSystem(path : String) : Promise<Map<String, Set>> {
    return Promise.create(function(resolve : Map<String, Set> -> Void, reject) {
      Fs.readFile(path, "utf8", function(err, content) {
        if(null != err) {
          reject(Error.fromDynamic(err));
          return;
        }
        try {
          resolve(cast Objects.toMap(Json.parse(content)));
        } catch(e : Dynamic) {
          reject(Error.fromDynamic(err));
        }
      });
    });
  }

  public function loadSets(source : Map<String, Set>) {
    setsByCode = source;
    sets = setsByCode.iterator().toArray();
    cards = sets.map(function(set) return set.cards)
              .flatten()
              .map(function(o : Card) : NormalizedCard {
                return o.merge({
                  normalizedName : null != o.name ? cleanName(o.name) : "",
                  normalizedText : null != o.text ? cleanName(o.text) : ""
                });
              })
              .order(function(a, b) return Ints.compare(b.multiverseid, a.multiverseid));
    cardsByName = generateMap(cards);
  }

  public static function generateMap(list : Array<Card>) : Map<String, Card> {
    var cards = new Map();
    for(card in list) {
      var cleanedName = cleanName(card.name);
      if(cards.exists(cleanedName)) continue;
      cards.set(cleanedName, card);
    }
    return cards;
  }

  static var pattern = ~/[^\w ]/g;
  public static function cleanName(name : String) {
    name = name.toLowerCase();
    name = Diactrics.clean(name);
    name = pattern.replace(name, "");
    name = name.trim();
    return name;
  }
}
