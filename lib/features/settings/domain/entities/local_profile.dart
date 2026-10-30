/// Local operator profile.
///
/// The application is single device and single user, so a single record is
/// stored and its name is used as the movement responsible.
class LocalProfile {
  const LocalProfile({this.id, required this.responsibleName});

  final int? id;
  final String responsibleName;

  static const LocalProfile empty = LocalProfile(responsibleName: '');

  bool get isEmpty => responsibleName.trim().isEmpty;

  LocalProfile copyWith({int? id, String? responsibleName}) {
    return LocalProfile(
      id: id ?? this.id,
      responsibleName: responsibleName ?? this.responsibleName,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LocalProfile &&
      other.id == id &&
      other.responsibleName == responsibleName;

  @override
  int get hashCode => Object.hash(id, responsibleName);
}
