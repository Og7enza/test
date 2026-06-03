/// Utilisateur de l'application (modernise l'ancien `UserModel`).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.walletAddress,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? walletAddress;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? walletAddress,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      walletAddress: walletAddress ?? this.walletAddress,
    );
  }
}
