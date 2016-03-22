package msb;

class MessageParser {
  public static function extractCards(message : String) : Array<String> {
    var pattern = ~/(?:[^\?]|^)\[([^\]]+)\]/;
    var result = [];
    while(pattern.match(message)) {
      result.push(pattern.matched(1));
      message = pattern.matchedRight();
    }
    return result;
  }
}
