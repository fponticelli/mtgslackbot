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
    // config
    var defaultTokens = js.Node.process.env["SLACKBOT_TOKENS"];
    var tokens = null == defaultTokens ? [] : defaultTokens.split(" ");
    var arangoConnectionString = js.Node.process.env["SLACKBOT_ARANGO_CONNECTION_STRING"];

    // db
    var db = new msb.Db(arangoConnectionString);
    db.init()
      .flatMap(function(_) {
        var api = new msb.Api();
        return api.loadSetsFromFileSystem(CARDS_FILE)
          .flatMap(db.uploadSets);
      })
      .failure(function(e) {
        trace("error", e);
      });

    // var api = new msb.Api();
    // console.log("Loading sets:");
    // api.loadSetsFromFileSystem(CARDS_FILE)
    //   .flatMap(function(sets) {
    //     console.log("  sets loaded");
    //     api.loadSets(sets);
    //     return api.count();
    //   })
    //   .success(function(count) {
    //     console.log('  ${count.integer()} cards processed');
    //
    //     // TODO collect port from args/env
    //     msb.Server.start(api, tokens);
    //     console.log('Server started');
    //   })
    //   .failure(function(_) {
    //     // TODO message
    //   });
  }
}
