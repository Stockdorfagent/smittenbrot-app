import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smittenbrot_app/core/services/supabase_service.dart';
import 'package:smittenbrot_app/features/cart/data/cart_repository.dart';
import 'package:smittenbrot_app/features/checkout/data/payment_repository.dart';
import 'package:smittenbrot_app/features/orders/models/order.dart';

// ── Enums ──

enum CheckoutStep { pickup, summary, payment, success }

enum CheckoutStatus { idle, processing, success, error }

// ── State ──

class CheckoutState {
  final CheckoutStep step;
  final CheckoutStatus status;
  final DateTime? pickupDate;
  final TimeOfDay? pickupTime;
  final String? pickupLocation;
  final String? errorMessage;
  final Order? order;

  const CheckoutState({
    this.step = CheckoutStep.pickup,
    this.status = CheckoutStatus.idle,
    this.pickupDate,
    this.pickupTime,
    this.pickupLocation,
    this.errorMessage,
    this.order,
  });

  CheckoutState copyWith({
    CheckoutStep? step,
    CheckoutStatus? status,
    DateTime? pickupDate,
    TimeOfDay? pickupTime,
    String? pickupLocation,
    String? errorMessage,
    Order? order,
    bool clearError = false,
    bool clearOrder = false,
  }) =>
      CheckoutState(
        step: step ?? this.step,
        status: status ?? this.status,
        pickupDate: pickupDate ?? this.pickupDate,
        pickupTime: pickupTime ?? this.pickupTime,
        pickupLocation: pickupLocation ?? this.pickupLocation,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        order: clearOrder ? null : (order ?? this.order),
      );
}

// ── Notifier ──

class CheckoutNotifier extends Notifier<CheckoutState> {
  late final PaymentRepository _paymentRepo;
  late final CartRepository _cartRepo;

  @override
  CheckoutState build() {
    _paymentRepo = PaymentRepository.instance;
    _cartRepo = CartRepository.instance;
    return const CheckoutState();
  }

  // ── Step navigation ──

  void goToStep(CheckoutStep step) => state = state.copyWith(step: step);

  void goToNextStep() {
    final index = CheckoutStep.values.indexOf(state.step);
    if (index < CheckoutStep.values.length - 1) {
      goToStep(CheckoutStep.values[index + 1]);
    }
  }

  void goToPreviousStep() {
    final index = CheckoutStep.values.indexOf(state.step);
    if (index > 0) {
      goToStep(CheckoutStep.values[index - 1]);
    }
  }

  // ── Pickup ──

  void selectPickupDate(DateTime date) => state = state.copyWith(pickupDate: date);
  void selectPickupTime(TimeOfDay time) => state = state.copyWith(pickupTime: time);
  void selectPickupLocation(String location) => state = state.copyWith(pickupLocation: location);

  // ── Checkout ──

  Future<void> initiateCheckout() async {
    final items = _cartRepo.getItems();
    if (items.isEmpty) {
      state = state.copyWith(status: CheckoutStatus.error, errorMessage: 'Ihr Warenkorb ist leer.');
      return;
    }

    if (state.pickupDate == null) {
      state = state.copyWith(status: CheckoutStatus.error, errorMessage: 'Bitte wählen Sie ein Abholdatum.');
      return;
    }

    state = state.copyWith(status: CheckoutStatus.processing);

    try {
      final supabase = SupabaseService();
      final user = supabase.currentUser;
      final fulfillmentDate = _formatDate(state.pickupDate!);

      // 1. Create PaymentIntent + order via website API
      final clientSecret = await _paymentRepo.createPaymentIntent(
        items: items,
        fulfillmentDate: fulfillmentDate,
        pickupLocationId: state.pickupLocation,
        customerEmail: user?.email,
        customerName: user?.userMetadata?['full_name'] as String?,
        customerId: user?.id,
      );

      // 2. Confirm payment with Stripe
      await _paymentRepo.confirmPayment(clientSecret);

      // 3. On success, the order was created by the API and
      //    the webhook will update payment status.
      _cartRepo.clear();
      state = state.copyWith(
        status: CheckoutStatus.success,
        step: CheckoutStep.success,
      );
    } catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Ein Fehler ist aufgetreten: ${e.toString()}',
      );
    }
  }

  void reset() => state = const CheckoutState();

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// ── Provider ──

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
);
