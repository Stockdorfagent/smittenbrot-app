import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smittenbrot_app/core/theme/app_colors.dart';
import 'package:smittenbrot_app/core/constants/app_constants.dart';
import 'package:smittenbrot_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:smittenbrot_app/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:smittenbrot_app/features/orders/models/order.dart';

// =============================================================================
// Checkout Screen
// =============================================================================

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutProvider);

    return Scaffold(
      appBar: _buildAppBar(context, ref, checkoutState),
      body: _buildBody(context, ref, checkoutState),
      bottomNavigationBar:
          checkoutState.step != CheckoutStep.success
              ? _StepIndicator(current: checkoutState.step)
              : null,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    CheckoutState state,
  ) {
    return AppBar(
      title: Text(_stepTitle(state.step)),
      leading: state.step != CheckoutStep.success
          ? IconButton(
              onPressed:
                  state.step == CheckoutStep.pickup
                      ? () => context.pop()
                      : () => ref.read(checkoutProvider.notifier).goToPreviousStep(),
              icon: const Icon(Icons.arrow_back),
            )
          : IconButton(
              onPressed: () => context.go('/catalog'),
              icon: const Icon(Icons.close),
            ),
    );
  }

  String _stepTitle(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.pickup:
        return 'Abholung';
      case CheckoutStep.summary:
        return 'Bestellübersicht';
      case CheckoutStep.payment:
        return 'Zahlung';
      case CheckoutStep.success:
        return 'Bestellung bestätigt';
    }
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, CheckoutState state) {
    if (state.status == CheckoutStatus.error) {
      return _ErrorView(
        message: state.errorMessage ?? 'Ein Fehler ist aufgetreten.',
        onRetry: () => ref.read(checkoutProvider.notifier).initiateCheckout(),
      );
    }

    if (state.status == CheckoutStatus.processing) {
      return const _ProcessingView();
    }

    switch (state.step) {
      case CheckoutStep.pickup:
        return _PickupStep();
      case CheckoutStep.summary:
        return _SummaryStep();
      case CheckoutStep.payment:
        return _PaymentStep();
      case CheckoutStep.success:
        return _SuccessStep(order: state.order);
    }
  }
}

// =============================================================================
// Step Indicator
// =============================================================================

class _StepIndicator extends StatelessWidget {
  final CheckoutStep current;

  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = CheckoutStep.values
        .where((s) => s != CheckoutStep.success)
        .toList();
    final currentIndex = steps.indexOf(current);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding * 2,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Line between circles
            return Container(
              width: 40,
              height: 2,
              color: i ~/ 2 < currentIndex
                  ? AppColors.primary
                  : AppColors.accentLight,
            );
          }
          final stepIndex = i ~/ 2;
          final isActive = stepIndex == currentIndex;
          final isCompleted = stepIndex < currentIndex;

          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.primary
                  : isActive
                      ? AppColors.primaryLight
                      : AppColors.accentLight.withValues(alpha: 0.4),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Step 1: Pickup
// =============================================================================

class _PickupStep extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PickupStep> createState() => _PickupStepState();
}

class _PickupStepState extends ConsumerState<_PickupStep> {
  // Available time slots (mock)
  static const _timeSlots = [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];

  // Pickup locations (mock)
  static const _locations = [
    'Smittenbrot – Stockdorf',
    'Smittenbrot – München Hauptbahnhof',
    'Smittenbrot – Garching',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutProvider);
    final notifier = ref.read(checkoutProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Abholdatum
          Text('Abholdatum', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: state.pickupDate ?? now.add(const Duration(days: 1)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 30)),
                locale: const Locale('de', 'DE'),
              );
              if (picked != null) notifier.selectPickupDate(picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.accentLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    state.pickupDate != null
                        ? '${state.pickupDate!.day}.${state.pickupDate!.month}.${state.pickupDate!.year}'
                        : 'Datum auswählen',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: state.pickupDate != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Section: Uhrzeit
          Text('Uhrzeit', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _timeSlots.map((slot) {
              final selected = state.pickupTime != null &&
                  state.pickupTime!.hour == slot.hour &&
                  state.pickupTime!.minute == slot.minute;
              return ChoiceChip(
                selected: selected,
                label: Text(
                  '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')} Uhr',
                ),
                onSelected: (_) => notifier.selectPickupTime(slot),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Section: Abholort
          Text('Abholort', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          ..._locations.map(
            (loc) => RadioListTile<String>(
              title: Text(loc),
              value: loc,
              groupValue: state.pickupLocation,
              onChanged: (v) {
                if (v != null) notifier.selectPickupLocation(v);
              },
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  state.pickupDate != null && state.pickupTime != null
                      ? () => notifier.goToNextStep()
                      : null,
              child: const Text('Weiter zur Bestellübersicht'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// =============================================================================
// Step 2: Order Summary
// =============================================================================

class _SummaryStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final notifier = ref.read(checkoutProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup info card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Abholung',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${checkoutState.pickupDate!.day}.${checkoutState.pickupDate!.month}.${checkoutState.pickupDate!.year} '
                    'um ${checkoutState.pickupTime!.hour.toString().padLeft(2, '0')}:${checkoutState.pickupTime!.minute.toString().padLeft(2, '0')} Uhr',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (checkoutState.pickupLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      checkoutState.pickupLocation!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Items header
          Text(
            'Artikel (${cartState.items.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Items list
          ...cartState.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Placeholder
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.restaurant_outlined,
                      size: 22,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${item.quantity} × ${item.product.formattedPrice}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.product.formattedPrice,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Totals
          _TotalRow(
            label: 'Zwischensumme',
            value: '€${cartState.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
          ),
          const _TotalRow(
            label: 'Lieferung',
            value: 'Kostenlos',
          ),
          const Divider(),
          _TotalRow(
            label: 'Gesamtsumme',
            value: '€${cartState.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
            isBold: true,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => notifier.goToNextStep(),
              child: const Text('Weiter zur Zahlung'),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: (isBold
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyLarge)
                ?.copyWith(
              color: isBold ? AppColors.primary : null,
              fontWeight: isBold ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Step 3: Payment
// =============================================================================

class _PaymentStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(checkoutProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zahlungsmethode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Stripe card (placeholder)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.accentLight),
                          ),
                          child: const Center(
                            child: Text(
                              '💳',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kredit- oder Debitkarte',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Zahlung per Stripe',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Placeholder for other methods
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accentLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.accentLight),
                          ),
                          child: const Center(
                            child: Text('💰', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Barzahlung bei Abholung',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Demnächst verfügbar',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textHint,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security note
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ihre Zahlungsdaten werden sicher per Stripe verarbeitet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Total
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gesamtsumme',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final total = ref.watch(cartProvider).totalPrice;
                      return Text(
                        '€${total.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => notifier.initiateCheckout(),
              icon: const Icon(Icons.lock, size: 18),
              label: const Text('Jetzt bezahlen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Back button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => notifier.goToPreviousStep(),
              child: const Text('Zurück zur Bestellübersicht'),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// Processing
// =============================================================================

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 24),
          Text(
            'Ihre Bestellung wird verarbeitet...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Error
// =============================================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Step 4: Success
// =============================================================================

class _SuccessStep extends ConsumerWidget {
  final Order? order;

  const _SuccessStep({this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success animation placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Bestellung erfolgreich!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Text(
              'Vielen Dank für Ihre Bestellung bei Smittenbrot.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            if (order != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Bestellnummer',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order!.id,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (order!.pickupDate != null)
                Text(
                  'Abholung: ${order!.pickupDate!.day}.${order!.pickupDate!.month}.${order!.pickupDate!.year}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(checkoutProvider.notifier).reset();
                  context.go('/catalog');
                },
                icon: const Icon(Icons.store_outlined),
                label: const Text('Zurück zum Sortiment'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/orders'),
                icon: const Icon(Icons.receipt_outlined),
                label: const Text('Meine Bestellungen'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
