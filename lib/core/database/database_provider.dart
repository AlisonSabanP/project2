import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'app_database.dart';

/// Database file name inside the application documents directory.
const String databaseFileName = 'inventario_bodega';

/// Opens the on device SQLite database used by the whole application.
AppDatabase openAppDatabase() {
  return AppDatabase(driftDatabase(name: databaseFileName));
}

/// In memory database, used by the widget and repository tests.
AppDatabase openInMemoryDatabase() {
  return AppDatabase(DatabaseConnection(NativeDatabase.memory()));
}
