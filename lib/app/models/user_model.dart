import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    this.id,
    this.email,
    this.name,
    this.emailVerified,
    this.image,
    this.username,
  });

  factory User.fromJson(
    Map<String, dynamic> json,
  ) {
    return User(
      id: json['id'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      username: json['username'] as String?,
      emailVerified: json['emailVerified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      // 'username': username,
      'image': image,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? image,
    bool? emailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      image: image ?? this.image,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        image,
        username,
        emailVerified,
      ];

  final String? id;
  final String? email;
  final String? name;
  final String? username;
  final String? image;
  final bool? emailVerified;
}
