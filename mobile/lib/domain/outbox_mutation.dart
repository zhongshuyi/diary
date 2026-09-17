class OutboxMutation {
  const OutboxMutation({
    required this.mutationId,
    required this.entityType,
    required this.entityId,
    required this.payload,
    this.retryCount = 0,
    this.nextRetryAt,
    required this.createdAt,
  });

  final String mutationId;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final int retryCount;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
}
