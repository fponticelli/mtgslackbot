package msb;

import ext.Client;
import ext.Slack;
import haxe.Json;
import thx.promise.Promise;
import mtgx.json.Card;
import msb.MessageParser;
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

  public function sendCards(channel, requests : Array<CardRequest>) {
    if(requests.length == 0) return;
    requests.each(function(request) {
      switch request {
        case Image(name):   getCard(channel, name).success(sendCardImage.bind(channel, _));
        case Rulings(name): getCard(channel, name).success(sendCardRulings.bind(channel, _));
        case Invalid:
      }
    });
  }

  function getCard(channel, name : String) {
    return api.getCard(name)
      .failure(function(err) {
        var text = 'unable to find card *${name}*';
        slack.api("chat.postMessage", {channel: channel, as_user: true, text: text }, function(a, b) { });
      });
  }

  public function sendCardImage(channel, card : Card) {
    var attachments = Json.stringify([{
        title: card.name,
        // title_link: card.store_url,
        image_url: getGathererImageUrl(card)
      }]);
    slack.api("chat.postMessage", {channel: channel, as_user: true, text: ' ', attachments: attachments}, function(a, b) {
      // trace(a, b);
    });
  }

  public function sendCardRulings(channel, card : Card) {
    var text = (null == card.rulings || card.rulings.length == 0) ?
      'no rulings found for *${card.name}*' :
      card.rulings.map(function(o) return ' • ${o.date}: _${o.text}_').join("\n");
    sendTextMessage(channel, text);
  }

  public function sendTextMessage(channel, text : String) {
    slack.api("chat.postMessage", {channel: channel, as_user: true, text: text}, function(a, b) {
      // trace(a, b);
    });
  }

  public function stop() {}

  public static function getGathererImageUrl(card : Card) {
    return 'http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=${card.multiverseid}&type=card';
  }
}

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
