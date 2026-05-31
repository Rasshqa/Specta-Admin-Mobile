enum TransactionStatus {
  pendingProof,
  success,
  rejected;

  static TransactionStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'SUCCESS':
        return TransactionStatus.success;
      case 'REJECTED':
        return TransactionStatus.rejected;
      case 'PENDING_PROOF':
      default:
        return TransactionStatus.pendingProof;
    }
  }

  String get apiValue {
    switch (this) {
      case TransactionStatus.success:
        return 'SUCCESS';
      case TransactionStatus.rejected:
        return 'REJECTED';
      case TransactionStatus.pendingProof:
        return 'PENDING_PROOF';
    }
  }
}

class SpectaTransaction {
  final int id;
  final String invoice;
  final String buyerName;
  final String email;
  final int ticketQuantity;
  final TransactionStatus status;
  final String? paymentProofUrl;
  final DateTime createdAt;

  const SpectaTransaction({
    required this.id,
    required this.invoice,
    required this.buyerName,
    required this.email,
    required this.ticketQuantity,
    required this.status,
    this.paymentProofUrl,
    required this.createdAt,
  });

  factory SpectaTransaction.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'];
    DateTime createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return SpectaTransaction(
      id: _parseInt(json['id']),
      invoice: (json['invoice'] ?? json['invoice_number'] ?? '').toString(),
      buyerName: (json['buyer_name'] ?? '').toString(),
      email: (json['email'] ?? json['buyer_email'] ?? '').toString(),
      ticketQuantity: _parseInt(json['ticket_quantity'] ?? json['quantity']),
      status: TransactionStatus.fromApi(
        (json['status'] ?? 'PENDING_PROOF').toString(),
      ),
      paymentProofUrl: _nullableString(
        json['payment_proof_url'] ?? json['payment_proof'],
      ),
      createdAt: createdAt,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice': invoice,
      'buyer_name': buyerName,
      'email': email,
      'ticket_quantity': ticketQuantity,
      'status': status.apiValue,
      'payment_proof_url': paymentProofUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
