// using msb.CardExtensions;
// import msb.Card;
using thx.Arrays;
using thx.Strings;
using thx.format.NumberFormat;
import js.Node.console;

// https://image.deckbrew.com/mtg/multiverseid/380368.jpg
class Main {
  static var CARDS_FILE = "assets/AllSets-x.json";
  public static function main() {
    var api = new msb.Api();
    console.log("Loading sets:");
    api.loadSetsFromFileSystem(CARDS_FILE)
      .mapSuccessPromise(function(sets) {
        console.log("  sets loaded");
        api.loadSets(sets);
        return api.count();
      })
      .success(function(count) {
        console.log('  ${count.integer()} cards processed');
        // get default bot tokens
        var defaultTokens = js.Node.process.env["SLACKBOT_TOKENS"];
        var tokens = null == defaultTokens ? [] : defaultTokens.split(" ");
        // TODO collect port from args/env
        msb.Server.start(api, tokens);
        console.log('Server started');
      })
      .failure(function(_) {
        // TODO message
      });
  }
}
