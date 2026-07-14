// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String?,
  phoneNumber: json['phone_number'] as String,
  isPhoneVerified: json['is_phone_verified'] as bool,
  profilePic: json['profile_pic'] as String?,
  grade: Grade.fromJson(json['grade'] as Map<String, dynamic>),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'phone_number': instance.phoneNumber,
  'is_phone_verified': instance.isPhoneVerified,
  'profile_pic': instance.profilePic,
  'grade': instance.grade,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  tokens: AuthToken.fromJson(json['tokens'] as Map<String, dynamic>),
  user: User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{'tokens': instance.tokens, 'user': instance.user};

RegisterResponse _$RegisterResponseFromJson(Map<String, dynamic> json) =>
    RegisterResponse(
      id: (json['id'] as num).toInt(),
      tokens: AuthToken.fromJson(json['tokens'] as Map<String, dynamic>),
      phoneNumber: json['phone_number'] as String,
      dateJoined: DateTime.parse(json['date_joined'] as String),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      grade: Grade.fromJson(json['grade'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RegisterResponseToJson(RegisterResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tokens': instance.tokens,
      'phone_number': instance.phoneNumber,
      'date_joined': instance.dateJoined.toIso8601String(),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'grade': instance.grade,
    };

VerifyPhoneResponse _$VerifyPhoneResponseFromJson(Map<String, dynamic> json) =>
    VerifyPhoneResponse(
      jwt: json['jwt'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VerifyPhoneResponseToJson(
  VerifyPhoneResponse instance,
) => <String, dynamic>{'jwt': instance.jwt, 'user': instance.user};

AuthToken _$AuthTokenFromJson(Map<String, dynamic> json) => AuthToken(
  access: json['access'] as String,
  refresh: json['refresh'] as String,
);

Map<String, dynamic> _$AuthTokenToJson(AuthToken instance) => <String, dynamic>{
  'access': instance.access,
  'refresh': instance.refresh,
};

UserSession _$UserSessionFromJson(Map<String, dynamic> json) => UserSession(
  token: AuthToken.fromJson(json['token'] as Map<String, dynamic>),
  user: User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserSessionToJson(UserSession instance) =>
    <String, dynamic>{'token': instance.token, 'user': instance.user};
