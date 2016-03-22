package msb;

class MessageParser {
  public static function extractCards(message : String) : Array<CardRequest> {
    var pattern = ~/(?:[^\?]|^)\[([^\]]+)\]/;
    var result = [];
    while(pattern.match(message)) {
      result.push(cardRequest(pattern.matched(1)));
      message = pattern.matchedRight();
    }
    return result;
  }

  public static function cardRequest(value : String) : CardRequest {
    var parts = value.split("|");
    if(parts.length == 1) {
      return Image(parts[0]);
    }
    return switch parts[1].toLowerCase() {
      case "image":
        Image(parts[0]);
      case "r" | "rules" | "rulings":
        Rulings(parts[0]);
      case _:
        Invalid;
    };
  }
}

enum CardRequest {
  Image(name : String);
  Rulings(name : String);
  Invalid;
}
