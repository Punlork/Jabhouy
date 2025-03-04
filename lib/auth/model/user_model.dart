class User {
  User({
    this.id,
    this.email,
    this.name,
    this.emailVerified,
    this.image,
  });

  factory User.fromJson(
    Map<String, dynamic> json,
  ) {
    return User(
      id: json['id'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      emailVerified: json['emailVerified'] as bool?,
    );
  }

  final String? id;
  final String? email;
  final String? name;
  final String? image; // Nullable since it might not always be present
  final bool? emailVerified;
}
