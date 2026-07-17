import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smittenbrot_app/core/theme/app_colors.dart';
import 'package:smittenbrot_app/features/orders/models/order.dart';
import 'package:smittenbrot_app/features/orders/presentation/providers/order_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadOrder() async {
    ref.invalidate(orderByIdProvider(widget.orderId));
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Bestellung stornieren?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Möchtest du diese Bestellung wirklich stornieren?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stornieren'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);
      final success =
          await ref.read(orderListProvider.notifier).cancelOrder(widget.orderId);
      if (mounted) {
        setState(() => _isCancelling = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bestellung wurde storniert'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fehler beim Stornieren'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          orderAsync.when(
            data: (order) => order?.displayId ?? 'Bestellung',
            loading: () => 'Bestellung',
            error: (_, __) => 'Fehler',
          ) ?? 'Bestellungsdetails',
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return _buildNotFound();
          return _buildDetail(order);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => _buildNotFound(),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Bestellung nicht gefunden',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(Order order) {
    final isActive = order.status.isActive;

    return RefreshIndicator(
      onRefresh: _loadOrder,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status section
            _buildStatusHeader(order),
            const SizedBox(height: 20),
            // Status timeline
            _buildStatusTimeline(order),
            const SizedBox(height: 20),
            // Items section
            _buildSectionTitle('Artikel'),
            const SizedBox(height: 8),
            _buildItemsList(order.items),
            const SizedBox(height: 20),
            // Total
            _buildTotalSection(order),
            const SizedBox(height: 20),
            // Pickup info
            _buildSectionTitle('Abholung'),
            const SizedBox(height: 8),
            _buildInfoCard([
              _buildInfoRow(
                Icons.location_on_outlined,
                'Standort',
                order.pickupLocation ?? 'Wird festgelegt',
              ),
              if (order.pickupDate != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Datum',
                  '${order.pickupDate!.day}.${order.pickupDate!.month}.${order.pickupDate!.year}',
                ),
            ]),
            const SizedBox(height: 20),
            // Payment info
            _buildSectionTitle('Zahlung'),
            const SizedBox(height: 8),
            _buildInfoCard([
              _buildInfoRow(
                Icons.credit_card_outlined,
                'Methode',
                order.paymentMethod ?? 'Nicht angegeben',
              ),
              _buildInfoRow(
                Icons.check_circle_outline,
                'Status',
                order.paymentStatus ?? 'Ausstehend',
                valueColor: order.paymentStatus == 'Bezahlt'
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ]),
            const SizedBox(height: 32),
            // Cancel button
            if (isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCancelling ? null : _cancelOrder,
                  icon: _isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: Text(
                    _isCancelling ? 'Wird storniert...' : 'Bestellung stornieren',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Order order) {
    Color statusColor;
    IconData statusIcon;
    switch (order.status) {
      case OrderStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
      case OrderStatus.confirmed:
        statusColor = AppColors.info;
        statusIcon = Icons.check_circle_outline;
      case OrderStatus.processing:
        statusColor = AppColors.categorySourdough;
        statusIcon = Icons.factory_outlined;
      case OrderStatus.ready:
        statusColor = AppColors.success;
        statusIcon = Icons.shopping_bag;
      case OrderStatus.pickedUp:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.done_all;
      case OrderStatus.cancelled:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_outlined;
    }

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bestellt am ${order.formattedDate}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(Order order) {
    final statuses = OrderStatus.values.toList();
    final currentIndex = statuses.indexOf(order.status);

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceDark, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status-Übersicht',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...statuses.map((status) {
              final idx = statuses.indexOf(status);
              final isCompleted = idx < currentIndex;
              final isCurrent = idx == currentIndex;
              final isFuture = idx > currentIndex;

              Color dotColor;
              if (isCompleted) dotColor = AppColors.success;
              else if (isCurrent) dotColor = AppColors.categorySourdough;
              else dotColor = AppColors.textHint;

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? dotColor
                                : isCompleted
                                    ? dotColor
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: dotColor,
                              width: isCurrent ? 3 : 2,
                            ),
                          ),
                        ),
                        if (idx < statuses.length - 1)
                          Container(
                            width: 2,
                            height: 24,
                            color: isCompleted
                                ? AppColors.success.withValues(alpha: 0.4)
                                : AppColors.textHint.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          status.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isFuture
                                ? AppColors.textHint
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 17,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildItemsList(List<OrderItem> items) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceDark, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.surfaceDark),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${items[i].quantity} × €${items[i].price.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '€${items[i].total.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalSection(Order order) {
    return Card(
      elevation: 0,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gesamtsumme',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.textOnPrimary,
              ),
            ),
            Text(
              order.formattedTotal,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceDark, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: rows),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
