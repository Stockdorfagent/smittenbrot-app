import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smittenbrot_app/core/providers/app_providers.dart';
import 'package:smittenbrot_app/features/subscriptions/data/subscription_repository.dart';
import 'package:smittenbrot_app/features/subscriptions/models/subscription.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final supabase = ref.read(supabaseServiceProvider);
  return SubscriptionRepository(supabase);
});

class SubscriptionListState {
  final List<Subscription> subscriptions;
  final bool isLoading;
  final String? error;
  final String? actionSuccessMessage;

  const SubscriptionListState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.error,
    this.actionSuccessMessage,
  });

  SubscriptionListState copyWith({
    List<Subscription>? subscriptions,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? actionSuccessMessage,
    bool clearSuccessMessage = false,
  }) {
    return SubscriptionListState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      actionSuccessMessage: clearSuccessMessage
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
    );
  }
}

class SubscriptionListNotifier extends StateNotifier<SubscriptionListState> {
  final SubscriptionRepository _repository;

  SubscriptionListNotifier(this._repository)
      : super(const SubscriptionListState());

  Future<void> fetchSubscriptions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final subs = await _repository.fetchSubscriptions();
      state = SubscriptionListState(subscriptions: subs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> pauseSubscription(String id) async {
    try {
      final success = await _repository.pauseSubscription(id);
      if (success) {
        state = state.copyWith(
          actionSuccessMessage: 'Abonnement pausiert',
          clearError: true,
        );
        await fetchSubscriptions();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> resumeSubscription(String id) async {
    try {
      final success = await _repository.resumeSubscription(id);
      if (success) {
        state = state.copyWith(
          actionSuccessMessage: 'Abonnement reaktiviert',
          clearError: true,
        );
        await fetchSubscriptions();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> cancelSubscription(String id) async {
    try {
      final success = await _repository.cancelSubscription(id);
      if (success) {
        state = state.copyWith(
          actionSuccessMessage: 'Abonnement gekündigt',
          clearError: true,
        );
        await fetchSubscriptions();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccessMessage: true);
  }
}

final subscriptionListProvider =
    StateNotifierProvider<SubscriptionListNotifier, SubscriptionListState>(
        (ref) {
  final repository = ref.read(subscriptionRepositoryProvider);
  return SubscriptionListNotifier(repository);
});
