// lib/models/transaction_log.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum LogStatus { paid, pending, awaitingUserConfirmation, fraud, cancelled, unknown }

class TransactionLog {
  final UuidValue logId;
  final String customerId;
  final String merchantId;
  final double amount;
  final DateTime timestamp;
  final LogStatus status;
  final String reason;

  TransactionLog({
    required this.logId,
    required this.customerId,
    required this.merchantId,
    required this.amount,
    required this.timestamp,
    required this.status,
    required this.reason,
  });

  factory TransactionLog.fromJson(Map<String, dynamic> json) {
    return TransactionLog(
      logId: UuidValue(json['log_id']),
      customerId: json['customer_id'],
      merchantId: json['merchant_id'],
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      status: _parseStatus(json['status']),
      reason: json['reason'] ?? 'No reason provided',
    );
  }

  static LogStatus _parseStatus(String? status) {
    switch (status) {
      case 'paid': return LogStatus.paid;
      case 'pending': return LogStatus.pending;
      case 'awaiting-user-confirmation': return LogStatus.awaitingUserConfirmation;
      case 'fraud': return LogStatus.fraud;
      case 'cancelled': return LogStatus.cancelled;
      default: return LogStatus.unknown;
    }
  }

  IconData get icon {
    switch (status) {
      case LogStatus.paid: return Icons.check_circle_rounded;
      case LogStatus.pending: return Icons.hourglass_empty_rounded;
      case LogStatus.awaitingUserConfirmation: return Icons.help_outline_rounded;
      case LogStatus.fraud: return Icons.gpp_bad_rounded;
      case LogStatus.cancelled: return Icons.cancel_rounded;
      default: return Icons.error_outline_rounded;
    }
  }

  Color get color {
    switch (status) {
      case LogStatus.paid: return Colors.green.shade600;
      case LogStatus.pending: return Colors.orange.shade700;
      case LogStatus.awaitingUserConfirmation: return Colors.blue.shade600;
      case LogStatus.fraud: return Colors.red.shade700;
      case LogStatus.cancelled: return Colors.grey.shade600;
      default: return Colors.black;
    }
  }
}