package msb;

using thx.Functions;
import js.Node;

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
  function cards(?q : String, ?limit = 100, ?offset = 0) {
    var query = Queries.parse(q);
    api.queryCards(query)
      .success.fn(response.send(_))
      .failure.fn(response.status(503).send(_));
  }

  @:get("/card/:name")
  function card(name : String) {
    api.queryCard(name)
      .success.fn(response.send(_))
      .failure.fn(response.status(503).send(_));
  }
}
