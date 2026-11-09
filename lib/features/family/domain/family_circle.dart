import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Family Circle group in CAREN.
class FamilyCircle {
  final String id;
  final String name;
  final String createdBy;
  final List<String> memberUids;
  final DateTime createdAt;

  const FamilyCircle({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.memberUids,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdBy': createdBy,
      'memberUids': memberUids,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FamilyCircle.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['createdAt'] as Timestamp?;
    return FamilyCircle(
      id: doc.id,
      name: data['name'] as String? ?? 'Family Circle',
      createdBy: data['createdBy'] as String? ?? '',
      memberUids: List<String>.from(data['memberUids'] as List? ?? []),
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}

