/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Smittenbrot';
  static const String appTagline = 'Handgemachtes Sauerteigbrot';
  static const String packageName = 'com.smittenbrot.app';

  // Supabase — live project
  static const String supabaseUrl = 'https://aoryokgzmpezanmlgxtl.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvcnlva2d6bXBlemFubWxneHRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2Njg2MzksImV4cCI6MjA5NjI0NDYzOX0.y0htsA0dC9-A_6-DRRBZERTucUiGDZpogOis_-WycBc';

  // Stripe — live keys
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_live_51TezkpQc4LrgIEdOIJ7YwFxhIV5ykDW78b02BvmHpu6gbyDrm1JNFhQCeWQO5VdzjCL1tfCGM6Ja3DsP8BGl8Ofq00hQhcB8ef',
  );

  // Bakery
  static const String bakeryName = 'Smittenbrot';
  static const String bakeryAddress = 'Stockdorf, Germany';
  static const String bakeryPhone = '+49 89 1234567';
  static const String bakeryEmail = 'hello@smittenbrot.de';
  static const String timezone = 'Europe/Berlin';

  // Ordering
  static const double minOrderAmount = 0.0;
  static const int maxItemsPerProduct = 20;
  static const int pickupTimeSlotMinutes = 15;

  // Backend API
  static const String websiteBaseUrl = 'https://smittenbrot-website.vercel.app';

  // Subscription
  static const int gracePeriodHours = 24;
  static const int cancellationNoticeHours = 24;

  // UI
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
}
