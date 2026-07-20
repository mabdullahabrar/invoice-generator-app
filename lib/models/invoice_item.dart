/// Represents a single product/service line item on an invoice.
///
/// Discount is stored as a percentage (0-100) applied to that line only,
/// which is how most small-business invoices express a line discount.
class InvoiceItem {
  final String id;
  String name;
  double quantity;
  double unitPrice;
  double discountPercent;

  InvoiceItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
  });

  /// Quantity * unit price, before any discount.
  double get lineSubtotal => quantity * unitPrice;

  /// The amount knocked off this line by its discount percentage.
  double get discountAmount => lineSubtotal * (discountPercent / 100);

  /// Final amount for this line after discount (pre-tax; tax is
  /// calculated at the invoice level on the summed subtotal).
  double get lineTotal => lineSubtotal - discountAmount;

  InvoiceItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? unitPrice,
    double? discountPercent,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercent': discountPercent,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}
