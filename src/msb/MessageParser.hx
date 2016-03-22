package msb;

class MessageParser {
  public static function extractCards(message : String) : Array<{ name : String }> {
    var pattern = ~/(?:[^\?]|^)\[([^\]]+)\]/;
    var result = [];
    while(pattern.match(message)) {
      result.push(cardRequest(pattern.matched(1)));
      message = pattern.matchedRight();
    }
    return result;
  }

  public static function cardRequest(value : String) {
    return { name : value };
  }
}
