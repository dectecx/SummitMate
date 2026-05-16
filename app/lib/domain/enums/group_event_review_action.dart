/// 揪團審核動作
enum GroupEventReviewAction {
  /// 核准
  approve,

  /// 拒絕
  reject,
}

extension GroupEventReviewActionExtension on GroupEventReviewAction {
  String get value {
    switch (this) {
      case GroupEventReviewAction.approve:
        return 'approve';
      case GroupEventReviewAction.reject:
        return 'reject';
    }
  }

  /// 轉換為後端需要的狀態字串
  String get apiStatus {
    switch (this) {
      case GroupEventReviewAction.approve:
        return 'approved';
      case GroupEventReviewAction.reject:
        return 'rejected';
    }
  }
}
