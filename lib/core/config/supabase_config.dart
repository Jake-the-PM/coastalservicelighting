/// Supabase configuration for Coastal Services Lighting
/// 
/// Project: coastal-services-lighting
/// Created: 2026-01-29

class SupabaseConfig {
  /// Your Supabase project URL
  static const String url = 'https://iulsgcuklidkijrbzwyw.supabase.co';

  /// Your Supabase anon (public) key
  static const String anonKey = 'sb_publishable_tUTYTHuzO5OTxCivg5B5qw_x2b3gTb5';

  /// Check if Supabase is configured
  static bool get isConfigured => 
      url != 'YOUR_SUPABASE_URL' && anonKey != 'YOUR_SUPABASE_ANON_KEY';
}
