import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../domain/entities/local_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/drift_profile_repository.dart';
import '../../domain/usecases/profile_usecases.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return DriftProfileRepository(ref.watch(databaseProvider));
});

final loadProfileProvider = Provider<LoadProfileUseCase>((ref) {
  return LoadProfileUseCase(ref.watch(profileRepositoryProvider));
});

final saveProfileProvider = Provider<SaveProfileUseCase>((ref) {
  return SaveProfileUseCase(ref.watch(profileRepositoryProvider));
});

/// The single local profile record.
final localProfileProvider = FutureProvider<LocalProfile>((ref) {
  return ref.watch(loadProfileProvider).call();
});

/// Responsible name applied to every new movement.
final responsibleNameProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(localProfileProvider.future);
  return profile.isEmpty ? 'Sin asignar' : profile.responsibleName;
});
