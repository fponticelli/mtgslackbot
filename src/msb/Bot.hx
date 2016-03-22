package msb;

import ext.Client;
import ext.Slack;
import haxe.Json;
import thx.promise.Promise;
using thx.Arrays;

class Bot {
  var api : Api;
  var slack : Slack;
  var userId : String;
  public function new(token : String, api : Api) {
    this.api = api;
    slack = new Slack(token);
    var client = new Client();
    client.on('connectFailed', onConnectFailed);
    client.on('connect', onConnect);
    slack.api('rtm.start', function(err, response) {
      userId = response.self.id;
      client.connect(response.url);
    });
  }

  function onConnectFailed(error) {
    trace('error connecting', error); // TODO
  }

  function onConnect(connection) {
    connection.on('message', onMessage);
  }

  function onMessage(message) {
    var data = haxe.Json.parse(message.utf8Data);
    if(data.user == userId || data.type != 'message') return;
    sendCards(data.channel, MessageParser.extractCards(data.text));
  }

  public function sendCards(channel, names : Array<String>) {
    if(names.length == 0) return;
    Promise.all(names.map(function(name) return api.getCard(name)))
      .success(function(cards) {
        cards = cards.compact();
        if(cards.length == 0) return;
        var attachments = Json.stringify(cards.map(function(card) return {
          title: card.name,
          // title_link: card.store_url,
          // image_url: card.getLatestEdition().image_url
        }));
        slack.api("chat.postMessage", {channel: channel, as_user: true, text: ' ', attachments: attachments}, function(_, _) {});
      });
  }

  public function stop() {

  }
}


//         var names = extractCards(data.text);
//         trace("match", names);
//         if(names.length > 0) {
//           var cardsfound = names.map(function(name) return map.get(msb.Api.cleanName(name))).compact();
//           trace('found: ${cardsfound.length}');
//           if(cardsfound.length > 0) {

//           }
//         }
//         var search = extractSearch(data.text).map(function(t) return t.toLowerCase());
//         trace("search", search);
//         if(search.length > 0) {
//           var found = cards.filter(function(card) {
//             return card.name.toLowerCase().containsAny(search);
//           }).slice(0, 50);
//           trace('found: ${found.length}');
//
//           // var attachments = haxe.Json.stringify(found.map(function(card) return {
//           //   title: card.name,
//           //   title_link: card.store_url
//           // }));
//
//           var text = found.map(function(card) return '<${card.store_url}|${card.name}>').join(", ");
//           // <http://www.foo.com|www.foo.com>
//
//           slack.api("chat.postMessage", {channel: data.channel, as_user: true, text: text, /*attachments: attachments*/}, function(_, _) {});
//         }
//       }
