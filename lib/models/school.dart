class School {
  final String id;
  final String name;
  final String managerId;
  final String? symbol; // סמל מוסד

  School({
    required this.id,
    required this.name,
    required this.managerId,
    this.symbol,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'managerId': managerId,
      'symbol': symbol,
    };
  }

  factory School.fromMap(String id, Map<String, dynamic> map) {
    return School(
      id: id,
      name: map['name'] ?? '',
      managerId: map['managerId'] ?? '',
      symbol: map['symbol'],
    );
  }
}

