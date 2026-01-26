import 'package:equatable/equatable.dart';

/// 揪團收藏功能的狀態基類
abstract class GroupEventFavoritesState extends Equatable {
  const GroupEventFavoritesState();

  @override
  List<Object> get props => [];
}

/// 初始狀態
class GroupEventFavoritesInitial extends GroupEventFavoritesState {}

/// 載入中
class GroupEventFavoritesLoading extends GroupEventFavoritesState {}

/// 載入完成 (包含目前的收藏 ID 清單)
class GroupEventFavoritesLoaded extends GroupEventFavoritesState {
  /// 收藏的揪團活動 ID 列表
  final List<String> favoriteIds;

  const GroupEventFavoritesLoaded(this.favoriteIds);

  @override
  List<Object> get props => [favoriteIds];

  /// 檢查特定 ID 是否在收藏中
  bool isFavorite(String id) => favoriteIds.contains(id);
}

/// 發生錯誤
class GroupEventFavoritesError extends GroupEventFavoritesState {
  final String message;

  const GroupEventFavoritesError(this.message);

  @override
  List<Object> get props => [message];
}
