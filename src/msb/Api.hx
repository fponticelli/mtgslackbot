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

  var colors : Array<String>;
  public function loadColors() : Promise<Array<String>> {
    if(null != colors)
      return Promise.value(colors);
    return Promise.value(colors = extractStringArrays(function(card) return card.colors));
  }

  var layouts : Array<String>;
  public function loadLayouts() : Promise<Array<String>> {
    if(null != layouts)
      return Promise.value(layouts);
    return Promise.value(layouts = extractStrings(function(card) return card.layout));
  }

  var formats : Array<String>;
  public function loadFormats() : Promise<Array<String>> {
    if(null != formats)
      return Promise.value(formats);
    return Promise.value(formats = extractStringArrays(function(card) return null == card.legalities ? [] : card.legalities.map(function(leg) return leg.format)));
  }

  var legalities : Array<String>;
  public function loadLegalities() : Promise<Array<String>> {
    if(null != legalities)
      return Promise.value(legalities);
    return Promise.value(legalities = extractStringArrays(function(card) return null == card.legalities ? [] : card.legalities.map(function(leg) return leg.legality)));
  }

  var manaCosts : Array<String>;
  public function loadManaCosts() : Promise<Array<String>> {
    if(null != manaCosts)
      return Promise.value(manaCosts);
    return Promise.value(manaCosts = extractStrings(function(card) return card.manaCost));
  }

  // power
  var powers : Array<String>;
  public function loadPowers() : Promise<Array<String>> {
    if(null != powers)
      return Promise.value(powers);
    return Promise.value(powers = extractStrings(function(card) return card.power));
  }
  // toughness
  var toughness : Array<String>;
  public function loadToughness() : Promise<Array<String>> {
    if(null != toughness)
      return Promise.value(toughness);
    return Promise.value(toughness = extractStrings(function(card) return card.toughness));
  }
  // rarity
  var rarities : Array<String>;
  public function loadRarities() : Promise<Array<String>> {
    if(null != rarities)
      return Promise.value(rarities);
    return Promise.value(rarities = extractStrings(function(card) return card.rarity));
  }
  // subtypes arr
  var subtypes : Array<String>;
  public function loadSubtypes() : Promise<Array<String>> {
    if(null != subtypes)
      return Promise.value(subtypes);
    return Promise.value(subtypes = extractStringArrays(function(card) return card.subtypes));
  }
  // type
  var types : Array<String>;
  public function loadTypes() : Promise<Array<String>> {
    if(null != types)
      return Promise.value(types);
    return Promise.value(types = extractStrings(function(card) return card.type));
  }
  // types arr
  var allTypes : Array<String>;
  public function loadAllTypes() : Promise<Array<String>> {
    if(null != allTypes)
      return Promise.value(allTypes);
    return Promise.value(allTypes = extractStringArrays(function(card) return card.types));
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
