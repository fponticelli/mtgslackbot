package ext;

import npm.common.Callback;

@:jsRequire("slack-node")
extern class Slack {
  function new(token : String) : Void;
  function api(method : String, ?args : {}, callback : Callback<Dynamic>) : Void;
}
