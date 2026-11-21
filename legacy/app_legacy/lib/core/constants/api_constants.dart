/// API 配置與 Actions
class ApiConfig {
  // API Actions
  static const String actionTripGetFull = 'trip_get_full';
  static const String actionItineraryList = 'itinerary_list';
  static const String actionItineraryUpdate = 'itinerary_update';
  static const String actionMessageList = 'message_list';
  static const String actionMessageCreate = 'message_create';
  static const String actionMessageCreateBatch = 'message_create_batch';
  static const String actionMessageDelete = 'message_delete';
  static const String actionWeatherGet = 'weather_get';

  // Poll API Actions (Flattened)
  static const String actionPollList = 'poll_list';
  static const String actionPollCreate = 'poll_create';
  static const String actionPollVote = 'poll_vote';
  static const String actionPollAddOption = 'poll_add_option';
  static const String actionPollDeleteOption = 'poll_delete_option';
  static const String actionPollClose = 'poll_close';
  static const String actionPollDelete = 'poll_delete';

  static const String actionSystemHeartbeat = 'system_heartbeat';
  static const String actionLogUpload = 'log_upload';

  // Gear Cloud API Actions
  static const String actionGearSetList = 'gear_set_list';
  static const String actionGearSetGet = 'gear_set_get';
  static const String actionGearSetDownload = 'gear_set_download';
  static const String actionGearSetUpload = 'gear_set_upload';
  static const String actionGearSetDelete = 'gear_set_delete';

  // GearLibrary API Actions (個人裝備庫)
  static const String actionGearLibraryUpload = 'gear_library_upload';
  static const String actionGearLibraryDownload = 'gear_library_download';

  // Trip Cloud API Actions (行程雲端同步)
  static const String actionTripList = 'trip_list';
  static const String actionTripCreate = 'trip_create';
  static const String actionTripUpdate = 'trip_update';
  static const String actionTripDelete = 'trip_delete';
  static const String actionTripSetActive = 'trip_set_active';
  static const String actionTripSync = 'trip_sync';

  // Auth API Actions
  static const String actionAuthRegister = 'auth_register';
  static const String actionAuthLogin = 'auth_login';
  static const String actionAuthValidate = 'auth_validate';
  static const String actionAuthVerifyEmail = 'auth_verify_email';
  static const String actionAuthResendCode = 'auth_resend_code';
  static const String actionAuthDeleteUser = 'auth_delete_user';
  static const String actionAuthRefreshToken = 'auth_refresh_token';
  static const String actionAuthUpdateProfile = 'auth_update_profile';

  // GroupEvent API Actions (揪團)
  static const String actionGroupEventList = 'group_event_list';
  static const String actionGroupEventGet = 'group_event_get';
  static const String actionGroupEventCreate = 'group_event_create';
  static const String actionGroupEventUpdate = 'group_event_update';
  static const String actionGroupEventClose = 'group_event_close';
  static const String actionGroupEventDelete = 'group_event_delete';
  static const String actionGroupEventApply = 'group_event_apply';
  static const String actionGroupEventCancelApplication = 'group_event_cancel_application';
  static const String actionGroupEventReviewApplication = 'group_event_review_application';
  static const String actionGroupEventMy = 'group_event_my';
  static const String actionGroupEventLike = 'group_event_like';
  static const String actionGroupEventUnlike = 'group_event_unlike';
  static const String actionGroupEventAddComment = 'group_event_add_comment';
  static const String actionGroupEventGetComments = 'group_event_get_comments';
  static const String actionGroupEventDeleteComment = 'group_event_delete_comment';
  static const String actionGroupEventGetApplications = 'group_event_get_applications';

  // Favorites API Actions
  static const String actionFavoritesGet = 'favorites_get';
  static const String actionFavoritesUpdate = 'favorites_update';
}
