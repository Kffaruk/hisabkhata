class Party {
  final String id;
  final String type; // 'customer' | 'supplier'
  final String name;
  final String phone;
  final int createdAt;

  const Party({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  factory Party.fromMap(Map<String, Object?> m) => Party(
        id: m['id'] as String,
        type: m['type'] as String,
        name: m['name'] as String,
        phone: (m['phone'] as String?) ?? '',
        createdAt: m['created_at'] as int,
      );

  bool get isSupplier => type == 'supplier';
  String get typeLabel => isSupplier ? 'সাপ্লায়ার' : 'কাস্টমার';
}

/// পার্টি + হিসাব। balance > 0 মানে "দেবো", balance < 0 মানে "পাবো"।
class PartyView {
  final Party party;
  final double balance;
  final int lastActivity;
  const PartyView(this.party, this.balance, this.lastActivity);
}

class Txn {
  final String id;
  final String partyId;
  final double gave; // দিলাম
  final double got; // পেলাম/কেনা
  final String note;
  final int date;
  final int createdAt;
  final int updatedAt;

  const Txn({
    required this.id,
    required this.partyId,
    required this.gave,
    required this.got,
    required this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Txn.fromMap(Map<String, Object?> m) => Txn(
        id: m['id'] as String,
        partyId: m['party_id'] as String,
        gave: (m['gave'] as num).toDouble(),
        got: (m['got'] as num).toDouble(),
        note: (m['note'] as String?) ?? '',
        date: m['date'] as int,
        createdAt: m['created_at'] as int,
        updatedAt: m['updated_at'] as int,
      );

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date);
}
