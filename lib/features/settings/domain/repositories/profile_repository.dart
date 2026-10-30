import '../entities/local_profile.dart';

/// Persistence contract for the single local profile record.
abstract interface class ProfileRepository {
  Stream<LocalProfile> watch();

  Future<LocalProfile> load();

  Future<void> save(LocalProfile profile);
}
