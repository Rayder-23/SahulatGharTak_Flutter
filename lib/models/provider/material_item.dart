/// A single line item in a booking's itemized material breakdown, sent
/// optionally alongside `verify-completion` (Feature 8, api.txt v3.16+).
/// `amount` is server-computed and never sent on a request.
class MaterialItem {
  final String itemName;
  final int quantity;
  final double unitPrice;

  const MaterialItem({required this.itemName, this.quantity = 1, required this.unitPrice});

  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}
