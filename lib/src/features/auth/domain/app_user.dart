class AppUser {
  const AppUser({
    required this.id,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String? fullName;
  final String? avatarUrl;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
