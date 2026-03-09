enum AnalyticsEventType {
  screenView, buttonTap, signUp, signIn, signOut,
  profileView, profileEdit, matchCreated, messageSent, messageRead,
  purchase, subscription, contentCreated, contentViewed, contentLiked,
  contentShared, contentReported, searchPerformed, filterApplied,
  notificationReceived, notificationTapped, error, custom,
}

enum CrashSeverity { fatal, nonFatal, warning, info }
enum AbTestVariant { control, variantA, variantB, variantC }

enum FunnelStep {
  appOpen, ageVerified, signUpStarted, signUpCompleted, profileCreated,
  firstInteraction, firstMatch, firstMessage, firstPurchase, retained7d, retained30d,
}
