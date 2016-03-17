package msb;

enum Query {
  Name(search : TextSearch);
  Text(search : TextSearch);

  // operators
  And(qs : Array<Query>);
  Or(qs : Array<Query>);
  Negate(q : Query);
}

enum TextSearch {
  // ExactMatch(text : String);
  Match(text : String);
  Contains(text : String);
  StartWith(text : String);
  EndWith(text : String);
}
