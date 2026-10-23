String? validateNama(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Nama wajib diisi.';
  if (text.length < 3) return 'Nama minimal 3 karakter.';
  if (text.length > 100) return 'Nama maksimal 100 karakter.';
  return null;
}

String? validatePhone(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Nomor telepon wajib diisi.';
  if (digits.length < 9 || digits.length > 15) {
    return 'Nomor telepon tidak valid.';
  }
  return null;
}

String? validateAlamat(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Alamat wajib diisi.';
  if (text.length < 5) return 'Alamat minimal 5 karakter.';
  return null;
}

String? validatePin(String? value) {
  final pin = value?.trim() ?? '';
  if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
    return 'PIN harus 6 digit angka.';
  }
  return null;
}

String? validatePinConfirmation(String? value, String pin) {
  final confirmation = value?.trim() ?? '';
  if (confirmation.isEmpty) return 'Konfirmasi PIN wajib diisi.';
  if (confirmation != pin) return 'Konfirmasi PIN tidak sama.';
  return null;
}

String? validateNoNota(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Nomor nota wajib diisi.';
  return null;
}
