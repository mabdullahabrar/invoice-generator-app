/// The three lifecycle states an invoice can be in.
enum InvoiceStatus { unpaid, paid, overdue }

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.unpaid:
        return 'Unpaid';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }

  static InvoiceStatus fromLabel(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'unpaid':
      default:
        return InvoiceStatus.unpaid;
    }
  }
}
