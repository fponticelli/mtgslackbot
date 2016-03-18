package msb;

enum Query {
  Artist(search : TextSearch);
  Flavor(search : TextSearch);
  Name(search : TextSearch);
  Text(search : TextSearch);
  CMC(search : NumberSearch);
  // color identity
  // colors
  // layout
  // formats
  // legalities
  // id
  // imagename (TextSearch)
  // manaCost
  // rulings

  // power
  // toughness
  // rarity
  // subtypes arr
  // type
  // types arr


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

enum NumberSearch {
  GT(value : Float);
  GTE(value : Float);
  LT(value : Float);
  LTE(value : Float);
  Equals(value : Float);
  Between(minInclusive : Float, maxInclusive : Float);
}
