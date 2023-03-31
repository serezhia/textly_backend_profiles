// ignore_for_file: public_member_api_docs

extension IsFirstNumber on String {
  bool isFirstNumber() {
    return int.tryParse(this[0]) != null;
  }
}
