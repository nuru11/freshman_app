/// Phone numbers (digits only after normalization) that get full in-app access.
const Set<String> _fullAccessPhoneDigits = {'920308061'};

String _digitsOnly(String? value) {
  if (value == null || value.isEmpty) return '';
  return value.replaceAll(RegExp(r'\D'), '');
}

/// Full access when the logged-in user's phone matches [allowed] entries.
/// Handles formats like `927052140`, `0927052140`, `+251927052140`.
bool hasFullAccessOverrideForPhone(String? phoneNumber) {
  final digits = _digitsOnly(phoneNumber);
  if (digits.isEmpty) return false;
  for (final allowed in _fullAccessPhoneDigits) {
    if (digits == allowed || digits.endsWith(allowed)) {
      return true;
    }
  }
  return false;
}
