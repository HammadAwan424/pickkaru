enum PollPeriod {
  morning,
  evening,
}

extension PollPeriodFirestore on PollPeriod {
  String get firestoreId => name;

  static PollPeriod fromFirestore(String value) {
    return PollPeriod.values.byName(value);
  }
}