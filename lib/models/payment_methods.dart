import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'payment_methods.g.dart';

@JsonSerializable()
class PaymentMethod {
  final int id;
  @JsonKey(name: 'bank_name')
  final String bankName;
  @JsonKey(name: 'account_name')
  final String accountName;
  @JsonKey(name: 'account_number')
  final String accountNumber;
  final String? image;

  PaymentMethod({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.image,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentMethodToJson(this);
}

class PaymentMethodTypeAdapter implements TypeAdapter<PaymentMethod> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    final json_ = Map<String, dynamic>.from(json);
    return PaymentMethod.fromJson(json_);
  }

  @override
  int get typeId => 5;

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    writer.write(obj.toJson());
  }
}
