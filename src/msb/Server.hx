package msb;

using thx.Functions;
import js.Node;
import thx.promise.Promise;
import express.Response;
import js.Node.console;
using thx.Arrays;
using thx.Strings;

class Server implements abe.IRoute {
  public static function start(api : Api, port = 9998, tokens : Array<String>) {
    var host = "0.0.0.0";
    var app = new abe.App();
    var server = new Server(api);
    app.router.register(server);
    app.http(port, host);
    // start bots
    tokens.each(server.startBot);
  }

  var bots : Map<String, Bot>;
  var api : Api;
  public function new(api : Api) {
    this.api = api;
    this.bots = new Map();
  }

  public function startBot(token : String) {
    if(bots.exists(token)) return;
    console.log('Start bot with token ${hideToken(token)}');
    var bot = new Bot(token, api);
    bots.set(token, bot);
  }

  public function stopBot(token : String) {
    var bot = bots.get(token);
    if(null == bot) return;
    bots.remove(token);
    bot.stop();
  }

  function hideToken(token : String) {
    var len = token.length,
        reveal = 5;
    return token.substring(0, reveal).rpad('*', len);
  }

  @:get("/")
  function index()
    response.send({
      version : "0.1.0"
    });

  @:get("/cards")
  @:args(Query)
  function cards(?q : String, ?offset = 0, ?limit = 100) {
    var query = Queries.parse(q);
    limitResponse(api.queryCards(query), offset, limit, response);
  }

  @:get("/artists")
  @:args(Query)
  function artists(?limit = 100, ?offset = 0)
    limitResponse(api.loadArtists(), offset, limit, response);

  @:get("/converted-mana-costs")
  @:args(Query)
  function convertedManaCosts(?limit = 100, ?offset = 0)
    limitResponse(api.loadConvertedManaCosts(), offset, limit, response);

  @:get("/color-identities")
  @:args(Query)
  function colorIdentities(?limit = 100, ?offset = 0)
    limitResponse(api.loadColorIdentities(), offset, limit, response);

  @:get("/colors")
  @:args(Query)
  function colors(?limit = 100, ?offset = 0)
    limitResponse(api.loadColors(), offset, limit, response);

  @:get("/layouts")
  @:args(Query)
  function layouts(?limit = 100, ?offset = 0)
    limitResponse(api.loadLayouts(), offset, limit, response);

  @:get("/formats")
  @:args(Query)
  function formats(?limit = 100, ?offset = 0)
    limitResponse(api.loadFormats(), offset, limit, response);

  @:get("/legalities")
  @:args(Query)
  function legalities(?limit = 100, ?offset = 0)
    limitResponse(api.loadLegalities(), offset, limit, response);

  @:get("/mana-costs")
  @:args(Query)
  function manaCosts(?limit = 100, ?offset = 0)
    limitResponse(api.loadManaCosts(), offset, limit, response);

  @:get("/powers")
  @:args(Query)
  function powers(?limit = 100, ?offset = 0)
    limitResponse(api.loadPowers(), offset, limit, response);

  @:get("/toughness")
  @:args(Query)
  function toughness(?limit = 100, ?offset = 0)
    limitResponse(api.loadToughness(), offset, limit, response);

  @:get("/rarities")
  @:args(Query)
  function rarities(?limit = 100, ?offset = 0)
    limitResponse(api.loadRarities(), offset, limit, response);

  @:get("/subtypes")
  @:args(Query)
  function subtypes(?limit = 100, ?offset = 0)
    limitResponse(api.loadSubtypes(), offset, limit, response);

  @:get("/types")
  @:args(Query)
  function types(?limit = 100, ?offset = 0)
    limitResponse(api.loadTypes(), offset, limit, response);

  @:get("/all-types")
  @:args(Query)
  function allTypes(?limit = 100, ?offset = 0)
    limitResponse(api.loadAllTypes(), offset, limit, response);

    // power
    // toughness
    // rarity
    // subtypes arr
    // type
    // types arr

  @:get("/card/:name")
  function card(name : String) {
    api.getCard(name)
    .success.fn(response.send(_))
    .failure.fn(response.status(503).send(_));
  }

  @:post("/bot")
  @:use(mw.BodyParser.json())
  @:args(Body)
  function createBot(token : String)
    startBot(token);

  @:delete("/bot")
  @:use(mw.BodyParser.json())
  @:args(Body)
  function destroyBot(token : String)
    stopBot(token);

  static function limitResponse<T>(promise : Promise<Array<T>>, offset, limit, response : Response) {
    promise
      .mapSuccess(function(values : Array<T>) return values.slice(offset, offset + limit))
      .success.fn(response.send(_))
      .failure.fn(response.status(503).send(_));
  }
}
