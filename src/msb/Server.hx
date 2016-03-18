package msb;

using thx.Functions;
import js.Node;
import thx.promise.Promise;
import express.Response;

class Server implements abe.IRoute {
  public static function start(api : Api, port = 9998) {
    var host = "0.0.0.0";
    var app = new abe.App();
    app.router.register(new Server(api));
    app.http(port, host);
  }

  var api : Api;
  public function new(api : Api) {
    this.api = api;
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

  @:get("/card/:name")
  function card(name : String) {
    api.queryCard(name)
    .success.fn(response.send(_))
    .failure.fn(response.status(503).send(_));
  }

  static function limitResponse<T>(promise : Promise<Array<T>>, offset, limit, response : Response) {
    promise
      .mapSuccess(function(values : Array<T>) return values.slice(offset, offset + limit))
      .success.fn(response.send(_))
      .failure.fn(response.status(503).send(_));
  }
}
