import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/privacy_settings.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';

/// Firestore-backed implementation of ProfileRepository.
/// Stores user documents at `users/{uid}` and privacy settings at `users/{uid}/settings/privacy`.
class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  FirestoreProfileRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(userId);

  DocumentReference<Map<String, dynamic>> get _privacyDoc =>
      _userDoc.collection('settings').doc('privacy');

  @override
  Future<UserProfile> getUserProfile() async {
    final snapshot = await _userDoc.get();
    if (!snapshot.exists) {
      // Default initial profile
      return UserProfile.empty(id: userId, email: '');
    }
    return UserProfile.fromFirestore(snapshot);
  }

  @override
  Stream<UserProfile> watchUserProfile() {
    return _userDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return UserProfile.empty(id: userId, email: '');
      }
      return UserProfile.fromFirestore(snapshot);
    });
  }

  @override
  Future<PrivacySettings> getPrivacySettings() async {
    final snapshot = await _privacyDoc.get();
    if (!snapshot.exists) {
      return PrivacySettings.defaultSettings();
    }
    final data = snapshot.data() ?? {};
    return PrivacySettings(
      shareCheckInStatusWithFamily:
          data['shareCheckInStatusWithFamily'] as bool? ?? true,
      shareSelfReportedWellness:
          data['shareSelfReportedWellness'] as bool? ?? true,
      shareCameraMeasurementsWithFamily:
          data['shareCameraMeasurementsWithFamily'] as bool? ?? false,
      storeMeasurementsLocallyOnly:
          data['storeMeasurementsLocallyOnly'] as bool? ?? true,
      enableSmartSpectraSimulatedMock:
          data['enableSmartSpectraSimulatedMock'] as bool? ?? false,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _userDoc.set(profile.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    await _privacyDoc.set({
      'shareCheckInStatusWithFamily': settings.shareCheckInStatusWithFamily,
      'shareSelfReportedWellness': settings.shareSelfReportedWellness,
      'shareCameraMeasurementsWithFamily':
          settings.shareCameraMeasurementsWithFamily,
      'storeMeasurementsLocallyOnly': settings.storeMeasurementsLocallyOnly,
      'enableSmartSpectraSimulatedMock':
          settings.enableSmartSpectraSimulatedMock,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await updateProfile(profile);
  }
}
