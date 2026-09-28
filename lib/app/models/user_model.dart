import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

part 'user_model.g.dart';

@CopyWith()
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
      'id': id,
      'email': email,
      'name': name,
      'image': image,
      'username': username,
      'emailVerified': emailVerified,
    };
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
