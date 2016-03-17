package ext;

import npm.common.Callback;

@:jsRequire("websocket", "client")
extern class Client {
  function new() : Void;
  function on(event : String, callback : Dynamic -> Void) : Void;
  function connect(url : String) : Void;
}
