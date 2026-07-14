import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vector_academy/models/models.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @JsonKey(name: 'is_phone_verified')
  final bool isPhoneVerified;
  @JsonKey(name: 'profile_pic')
  final String? profilePic;
  final Grade grade;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  User({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.phoneNumber,
    required this.isPhoneVerified,
    this.profilePic,
    required this.grade,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final AuthToken tokens;
  final User user;

  AuthResponse({required this.tokens, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class RegisterResponse {
  final int id;
  final AuthToken tokens;
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @JsonKey(name: 'date_joined')
  final DateTime dateJoined;

  @JsonKey(name: 'first_name')
  String firstName;
  @JsonKey(name: 'last_name')
  String lastName;
  final Grade grade;
  RegisterResponse({
    required this.id,
    required this.tokens,
    required this.phoneNumber,
    required this.dateJoined,
    required this.firstName,
    required this.lastName,
    required this.grade,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
  User toUser() => User(
    id: id,
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    isPhoneVerified: true,
    grade: grade,
    createdAt: dateJoined.toIso8601String(),
    updatedAt: dateJoined.toIso8601String(),
  );
}

@JsonSerializable()
class VerifyPhoneResponse {
  final String jwt;
  final User user;

  VerifyPhoneResponse({required this.jwt, required this.user});

  factory VerifyPhoneResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyPhoneResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyPhoneResponseToJson(this);
}

class UserTypeAdapter implements TypeAdapter<User> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;

    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      isPhoneVerified: json['is_phone_verified'],
      grade: json['grade'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  @override
  int get typeId => 8;

  @override
  void write(BinaryWriter writer, User obj) {
    writer.write(obj.toJson());
  }
}

@JsonSerializable()
class AuthToken {
  final String access;
  final String refresh;

  AuthToken({required this.access, required this.refresh});

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenFromJson(json);
  Map<String, dynamic> toJson() => _$AuthTokenToJson(this);
}

@JsonSerializable()
class UserSession {
  final AuthToken token;
  final User user;

  UserSession({required this.token, required this.user});

  factory UserSession.fromJson(Map<String, dynamic> json) =>
      _$UserSessionFromJson(json);
  Map<String, dynamic> toJson() => _$UserSessionToJson(this);
}

class UserSessionTypeAdapter implements TypeAdapter<UserSession> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    final json_ = Map<String, dynamic>.from(json);
    return UserSession.fromJson(json_);
  }

  @override
  int get typeId => 10;

  @override
  void write(BinaryWriter writer, UserSession obj) {
    writer.write(obj.toJson());
  }
}

class AuthTokenTypeAdapter implements TypeAdapter<AuthToken> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    final json_ = Map<String, dynamic>.from(json);
    return AuthToken.fromJson(json_);
  }

  @override
  int get typeId => 11;

  @override
  void write(BinaryWriter writer, AuthToken obj) {
    writer.write(obj.toJson());
  }
}
