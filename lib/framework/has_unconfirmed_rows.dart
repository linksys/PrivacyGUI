/// Settings that can hold a row the router has not yet given an identity.
///
/// A row added on the page has no instance path until the router creates it,
/// and the path comes back only by reading the router. When the read after a
/// save fails, the Preservable delegate keeps the page on what was written
/// (#1212) — but for an added row that is not what the router holds: the
/// router has the row, and the page still calls it new. Saving that again
/// adds the row a second time, and a delete of it is never sent (the save's
/// diff skips rows without a path).
///
/// So the delegate asks this before it writes: while [hasUnconfirmedRows] is
/// true and the last read failed, `save()` reads the router first and does not
/// write until it can. Settings whose rows always carry a path — a page of
/// switches — need not implement it.
abstract interface class HasUnconfirmedRows {
  /// Whether any row here has no instance path the router assigned.
  bool get hasUnconfirmedRows;
}
