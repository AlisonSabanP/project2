import 'package:drift/drift.dart' as drift;

import '../../../core/database/app_database.dart' as db;
import '../domain/entities/local_profile.dart';
import '../domain/repositories/profile_repository.dart';

/// Drift backed storage for the single local profile record.
class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<LocalProfile> watch() => _query().watchSingleOrNull().map(_map);

  @override
  Future<LocalProfile> load() async => _map(await _query().getSingleOrNull());

  @override
  Future<void> save(LocalProfile profile) async {
    final existing = await _query().getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.profiles).insert(
            db.ProfilesCompanion.insert(
              responsibleName: profile.responsibleName,
            ),
          );
      return;
    }

    await (_db.update(_db.profiles)..where((t) => t.id.equals(existing.id)))
        .write(
      db.ProfilesCompanion(
        responsibleName: drift.Value(profile.responsibleName),
      ),
    );
  }

  drift.SimpleSelectStatement<db.$ProfilesTable, db.Profile> _query() {
    return _db.select(_db.profiles)
      ..orderBy([(t) => drift.OrderingTerm(expression: t.id)])
      ..limit(1);
  }

  LocalProfile _map(db.Profile? row) {
    if (row == null) {
      return LocalProfile.empty;
    }
    return LocalProfile(id: row.id, responsibleName: row.responsibleName);
  }
}
