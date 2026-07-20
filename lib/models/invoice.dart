import 'invoice_item.dart';
import 'invoice_status.dart';

/// The core Invoice entity.
///
/// Business details are stored on the invoice itself (not just referenced
/// from Settings) so that if the user later edits their company info in
/// Settings, previously-generated invoices still show the business info
/// that was correct at the time they were created.
///
/// [toJson]/[fromJson] is the single serialization format used both for
/// local storage (Hive) and for JSON backup export — one format only,
/// so there's nothing to keep in sync between two encodings.
class Invoice {
  int? id;
  String invoiceNumber;
  DateTime invoiceDate;
  DateTime dueDate;

  String businessName;
  String businessAddress;
  String businessEmail;
  String businessPhone;

  String customerName;
  String customerAddress;
  String customerEmail;
  String customerPhone;

  List<InvoiceItem> items;
  double taxPercent;
  String notes;
  String status;
  DateTime createdAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.businessName,
    required this.businessAddress,
    required this.businessEmail,
    required this.businessPhone,
    required this.customerName,
    required this.customerAddress,
    required this.customerEmail,
    required this.customerPhone,
    required this.items,
    required this.taxPercent,
    this.notes = '',
    this.status = 'Unpaid',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get taxAmount => subtotal * (taxPercent / 100);

  double get grandTotal => subtotal + taxAmount;

  InvoiceStatus get statusEnum => InvoiceStatusX.fromLabel(status);

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? businessName,
    String? businessAddress,
    String? businessEmail,
    String? businessPhone,
    String? customerName,
    String? customerAddress,
    String? customerEmail,
    String? customerPhone,
    List<InvoiceItem>? items,
    double? taxPercent,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items.map((e) => e.copyWith()).toList(),
      taxPercent: taxPercent ?? this.taxPercent,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Plain-value map: safe to hand to Hive (which stores Map/List/String
  /// natively) and to `jsonEncode` (used for the backup export file).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessEmail': businessEmail,
      'businessPhone': businessPhone,
      'customerName': customerName,
      'customerAddress': customerAddress,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'items': items.map((e) => e.toMap()).toList(),
      'taxPercent': taxPercent,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Builds an [Invoice] from a decoded map. Defensively normalizes
  /// nested maps/lists, since Hive can hand back `Map<dynamic, dynamic>`
  /// / `List<dynamic>` rather than the strongly-typed versions you get
  /// from `jsonDecode`.
  factory Invoice.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => InvoiceItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return Invoice(
      id: json['id'] as int?,
      invoiceNumber: json['invoiceNumber'] as String,
      invoiceDate: DateTime.parse(json['invoiceDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      businessName: json['businessName'] as String? ?? '',
      businessAddress: json['businessAddress'] as String? ?? '',
      businessEmail: json['businessEmail'] as String? ?? '',
      businessPhone: json['businessPhone'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerAddress: json['customerAddress'] as String? ?? '',
      customerEmail: json['customerEmail'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      items: items,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'Unpaid',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
