import '../../../../core/error/domain_exception.dart';
import '../entities/local_profile.dart';
import '../repositories/profile_repository.dart';

/// Reads the local profile, falling back to an empty profile.
class LoadProfileUseCase {
  const LoadProfileUseCase(this._profiles);

  final ProfileRepository _profiles;

  Future<LocalProfile> call() => _profiles.load();
}

/// Stores the default responsible name used by inventory movements.
class SaveProfileUseCase {
  const SaveProfileUseCase(this._profiles);

  final ProfileRepository _profiles;

  Future<void> call(String responsibleName) async {
    final trimmed = responsibleName.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('El nombre del responsable es obligatorio.');
    }
    if (trimmed.length > 80) {
      throw const ValidationException(
        'El nombre del responsable no puede superar 80 caracteres.',
      );
    }
    await _profiles.save(LocalProfile(responsibleName: trimmed));
  }
}
