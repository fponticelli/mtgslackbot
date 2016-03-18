package msb;

import msb.Query;
using thx.Strings;
using thx.Arrays;

class Queries {
  public static function parse(q : String) : Query {
    return Name(Contains(q));
  }

  public static function query(cards : Array<NormalizedCard>, q : Query) : Array<NormalizedCard> {
    var filter = generateFilter(q);
    return cards.filter(filter);
  }

  public static function generateFilter(q : Query) : NormalizedCard -> Bool {
    return switch q {
      case Artist(search): queryTextSearch(search, function(card) return card.artist);
      case Flavor(search): queryTextSearch(search, function(card) return card.normalizedFlavor);
      case Name(search):   queryTextSearch(search, function(card) return card.normalizedName);
      case Text(search):   queryTextSearch(search, function(card) return card.normalizedText);
      case CMC(search):    queryNumberSearch(search, function(card) return card.cmc);
      case Negate(q):
        var filter = generateFilter(q);
        function(card) return !filter(card);
      case Or(qs):
        var filters = qs.map(generateFilter);
        function(card) {
          for(filter in filters)
            if(filter(card))
              return true;
          return false;
        }
      case And(qs):
        var filters = qs.map(generateFilter);
        function(card) {
          for(filter in filters)
            if(!filter(card))
              return false;
          return true;
        }
    };
  }

  public static function queryNumberSearch(search : NumberSearch, extractor : NormalizedCard -> Float) {
    return switch search {
      case GT(value):
        function(card) return extractor(card) > value;
      case GTE(value):
        function(card) return extractor(card) >= value;
      case LT(value):
        function(card) return extractor(card) < value;
      case LTE(value):
        function(card) return extractor(card) <= value;
      case Equals(value):
        function(card) return extractor(card) == value;
      case Between(minInclusive, maxInclusive):
        function(card) {
          var value = extractor(card);
          return value >= minInclusive && value <= maxInclusive;
        };
    };
  }

  public static function queryTextSearch(search : TextSearch, extractor : NormalizedCard -> String) {
    return switch search {
      case Match(Api.cleanName(_) => text):
        function(card) return extractor(card) == text;
      case Contains(Api.cleanName(_) => text):
        function(card) return extractor(card).contains(text);
      case StartWith(Api.cleanName(_) => text):
        function(card) return extractor(card).startsWith(text);
      case EndWith(Api.cleanName(_) => text):
        function(card) return extractor(card).endsWith(text);
      case _:
        throw "should never happen";
    };
  }
}
