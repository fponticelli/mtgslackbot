package msb;

import thx.Objects;
import haxe.Json;
import thx.Error;
import thx.promise.Promise;
import thx.text.Diactrics;
import thx.Set;
using thx.Arrays;
using thx.Floats;
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
                  normalizedText : null != o.text ? cleanName(o.text) : "",
                  normalizedFlavor : null != o.flavor ? cleanName(o.flavor) : ""
                });
              })
              .order(function(a, b) return Ints.compare(b.multiverseid, a.multiverseid));
    cardsByName = generateMap(cards);
  }

  // card details
  var artists : Array<String>;
  public function loadArtists() : Promise<Array<String>> {
    if(null != artists)
      return Promise.value(artists);
    return Promise.value(artists = extractStrings(function(card) return card.artist));
  }

  var convertedManaCosts : Array<Float>;
  public function loadConvertedManaCosts() : Promise<Array<Float>> {
    if(null != convertedManaCosts)
      return Promise.value(convertedManaCosts);
    var values = extractStrings(function(card) return '${card.cmc}');
    return Promise.value(
      convertedManaCosts = values
        .map(Std.parseFloat)
        .order(Floats.compare)
    );
  }

  var colorIdentities : Array<String>;
  public function loadColorIdentities() : Promise<Array<String>> {
    if(null != colorIdentities)
      return Promise.value(colorIdentities);
    return Promise.value(colorIdentities = extractStringArrays(function(card) return card.colorIdentity));
  }

  // helpers
  function extractStringArrays(extractor : NormalizedCard -> Array<String>)
    return extractArrays(extractor, thx.Set.createString()).toArray().order(Strings.compare);

  function extractStrings(extractor : NormalizedCard -> String) {
    var set = extractValues(extractor, thx.Set.createString());
    set.remove("undefined"); // beh
    return set.toArray().order(Strings.compare);
  }

  function extractArrays<T>(extractor : NormalizedCard -> Array<T>, set : thx.Set<T>) {
    return cards.reduce(function(acc : thx.Set<T>, card) {
      var values = extractor(card);
      if(null == values)
        return acc;
      for(v in values)
        acc.add(v);
      return acc;
    }, set);
  }

  function extractValues<T>(extractor : NormalizedCard -> T, set : thx.Set<T>) {
    return cards.reduce(function(acc : thx.Set<T>, card) {
      var value = extractor(card);
      if(null != value)
        acc.add(value);
      return acc;
    }, set);
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
