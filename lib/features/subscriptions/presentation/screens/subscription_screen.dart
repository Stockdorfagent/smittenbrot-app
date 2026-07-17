import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smittenbrot_app/core/theme/app_colors.dart';
import 'package:smittenbrot_app/features/subscriptions/models/subscription.dart';
import 'package:smittenbrot_app/features/subscriptions/presentation/providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final Set<String> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(subscriptionListProvider.notifier).fetchSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionListProvider);

    ref.listen<SubscriptionListState>(subscriptionListProvider, (prev, next) {
      if (next.actionSuccessMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionSuccessMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        // Clear message after showing
        Future.microtask(() {
          ref.read(subscriptionListProvider.notifier).clearMessages();
        });
      }
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Future.microtask(() {
          ref.read(subscriptionListProvider.notifier).clearMessages();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Meine Abonnements',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: _buildBody(subState),
    );
  }

  Widget _buildBody(SubscriptionListState subState) {
    if (subState.isLoading && subState.subscriptions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (subState.error != null && subState.subscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Fehler beim Laden der Abonnements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subState.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(subscriptionListProvider.notifier).fetchSubscriptions(),
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (subState.subscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.repeat_outlined,
                  size: 80,
                  color: AppColors.textHint.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              Text(
                'Noch keine Abonnements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Abonniere dein Lieblingsbrot\nund erhalte es wöchentlich frisch.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go('/catalog'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Neues Abo erstellen'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(subscriptionListProvider.notifier).fetchSubscriptions(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...subState.subscriptions.map(
            (sub) => _SubscriptionCard(
              subscription: sub,
              isExpanded: _expandedCards.contains(sub.id),
              onToggleExpand: () {
                setState(() {
                  if (_expandedCards.contains(sub.id)) {
                    _expandedCards.remove(sub.id);
                  } else {
                    _expandedCards.add(sub.id);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // New subscription button
          Center(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/catalog'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Neues Abo erstellen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  final Subscription subscription;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _SubscriptionCard({
    required this.subscription,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  Color _statusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return AppColors.success;
      case SubscriptionStatus.paused:
        return AppColors.warning;
      case SubscriptionStatus.cancellationPending:
        return AppColors.warning;
      case SubscriptionStatus.cancelled:
        return AppColors.error;
      case SubscriptionStatus.paymentFailed:
        return AppColors.error;
    }
  }

  Color _statusBackground(SubscriptionStatus status) {
    return _statusColor(status).withValues(alpha: 0.12);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.surfaceDark, width: 1),
        ),
        child: Column(
          children: [
            // Main card content
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onToggleExpand,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name + status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.breakfast_dining_outlined,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subscription.productNames,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subscription.formattedPrice,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _statusBackground(subscription.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            subscription.status.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(subscription.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Next pickup
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          subscription.nextPickupLabel != null
                              ? 'Nächste Abholung: ${subscription.nextPickupLabel}'
                              : 'Nächste Abholung: -',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.expand_more,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Action buttons
            if (isExpanded) _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final status = subscription.status;
    final isActiveStatus = status == SubscriptionStatus.active;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceDark),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          if (status == SubscriptionStatus.active) ...[
            _ActionChip(
              icon: Icons.pause_circle_outline,
              label: 'Pausieren',
              color: AppColors.warning,
              onTap: () => _confirmAction(
                context,
                title: 'Abonnement pausieren?',
                message:
                    'Möchtest du «${subscription.productNames}» wirklich pausieren?',
                actionLabel: 'Pausieren',
                onConfirm: () {
                  ref
                      .read(subscriptionListProvider.notifier)
                      .pauseSubscription(subscription.id);
                },
              ),
            ),
          ],
          if (status == SubscriptionStatus.paused) ...[
            _ActionChip(
              icon: Icons.play_circle_outline,
              label: 'Reaktivieren',
              color: AppColors.success,
              onTap: () {
                ref
                    .read(subscriptionListProvider.notifier)
                    .resumeSubscription(subscription.id);
              },
            ),
          ],
          if (isActiveStatus || status == SubscriptionStatus.paused) ...[
            _ActionChip(
              icon: Icons.cancel_outlined,
              label: 'Kündigen',
              color: AppColors.error,
              onTap: () => _confirmAction(
                context,
                title: 'Abonnement kündigen?',
                message:
                    'Möchtest du «${subscription.productNames}» wirklich kündigen?',
                actionLabel: 'Kündigen',
                isDestructive: true,
                onConfirm: () {
                  ref
                      .read(subscriptionListProvider.notifier)
                      .cancelSubscription(subscription.id);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  isDestructive ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// Extension to get calendar week-of-year from DateTime.
extension _WeekOfYear on DateTime {
  int get weekOfYear {
    final firstOfYear = DateTime(year, 1, 1);
    final days = difference(firstOfYear).inDays;
    // ISO 8601: weeks start on Monday
    final woy = ((days + firstOfYear.weekday - 1) / 7).ceil();
    return woy;
  }
}
