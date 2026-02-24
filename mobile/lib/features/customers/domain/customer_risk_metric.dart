class CustomerRiskMetric {
  const CustomerRiskMetric({
    required this.customerId,
    required this.riskScore,
    required this.riskLevel,
    required this.oldestDueDays,
    required this.outstandingAmount,
    this.avgDaysToPay = 0,
    this.onTimeRate = 0,
    this.paymentFrequency30d = 0,
    this.factors = const CustomerRiskFactors(),
  });

  final String customerId;
  final int riskScore;
  final String riskLevel;
  final int oldestDueDays;
  final double outstandingAmount;
  final double avgDaysToPay;
  final double onTimeRate;
  final double paymentFrequency30d;
  final CustomerRiskFactors factors;

  bool get isHighRisk => riskLevel.toLowerCase() == 'red';
  bool get isMediumRisk => riskLevel.toLowerCase() == 'yellow';

  factory CustomerRiskMetric.fromJson(Map<String, dynamic> json) {
    int toInt(Object? v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
    double toDouble(Object? v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

    return CustomerRiskMetric(
      customerId: json['customer_id']?.toString() ?? '',
      riskScore: toInt(json['risk_score']),
      riskLevel: json['risk_level']?.toString() ?? 'green',
      oldestDueDays: toInt(json['oldest_due_days']),
      outstandingAmount: toDouble(json['outstanding_amount']),
      avgDaysToPay: toDouble(json['avg_days_to_pay']),
      onTimeRate: toDouble(json['on_time_rate']),
      paymentFrequency30d: toDouble(json['payment_frequency_30d']),
      factors: CustomerRiskFactors.fromJson(json['factors']),
    );
  }
}

class CustomerRiskFactors {
  const CustomerRiskFactors({
    this.oldestDueFactor = 0,
    this.avgDaysToPayFactor = 0,
    this.lateBehaviorFactor = 0,
    this.outstandingSpikeFactor = 0,
  });

  final double oldestDueFactor;
  final double avgDaysToPayFactor;
  final double lateBehaviorFactor;
  final double outstandingSpikeFactor;

  factory CustomerRiskFactors.fromJson(Object? json) {
    if (json is! Map) return const CustomerRiskFactors();
    double toDouble(Object? v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
    return CustomerRiskFactors(
      oldestDueFactor: toDouble(json['oldest_due_factor']),
      avgDaysToPayFactor: toDouble(json['avg_days_to_pay_factor']),
      lateBehaviorFactor: toDouble(json['late_behavior_factor']),
      outstandingSpikeFactor: toDouble(json['outstanding_spike_factor']),
    );
  }
}
