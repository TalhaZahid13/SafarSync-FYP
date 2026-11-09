// Backend numeric fields (price, cost, rating, lat/lng, ids, ...) can arrive
// as String, int, or double depending on the SQL column/expression that
// produced them (Postgres numeric columns, computed SQL expressions, and
// legacy string-typed id columns all serialize differently over JSON).
// Never cast an unknown JSON value directly with `as num`/`as int`/`as
// double` — a String value makes that throw
// "type 'String' is not a subtype of type 'num?' in type cast" at runtime.
// Use these helpers instead, which accept any of those shapes safely.

num? asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

double? asDouble(dynamic value) => asNum(value)?.toDouble();

int? asInt(dynamic value) => asNum(value)?.toInt();
