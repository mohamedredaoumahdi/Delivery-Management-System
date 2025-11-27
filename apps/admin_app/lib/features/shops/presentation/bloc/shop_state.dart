import 'package:equatable/equatable.dart';
import '../../data/models/shop_model.dart';

abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {
  const ShopInitial();
}

class ShopLoading extends ShopState {
  const ShopLoading();
}

class ShopsLoaded extends ShopState {
  final List<ShopModel> shops;
  final List<ShopModel> filteredShops;
  final String? selectedCategory;
  final bool? selectedStatus;
  final String? searchQuery;

  const ShopsLoaded({
    required this.shops,
    required this.filteredShops,
    this.selectedCategory,
    this.selectedStatus,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [shops, filteredShops, selectedCategory, selectedStatus, searchQuery];

  ShopsLoaded copyWith({
    List<ShopModel>? shops,
    List<ShopModel>? filteredShops,
    String? selectedCategory,
    bool? selectedStatus,
    String? searchQuery,
  }) {
    return ShopsLoaded(
      shops: shops ?? this.shops,
      filteredShops: filteredShops ?? this.filteredShops,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ShopDetailsLoaded extends ShopState {
  final ShopModel shop;

  const ShopDetailsLoaded(this.shop);

  @override
  List<Object?> get props => [shop];
}

class ShopError extends ShopState {
  final String message;

  const ShopError(this.message);

  @override
  List<Object?> get props => [message];
}

class ShopUpdated extends ShopState {
  final ShopModel shop;

  const ShopUpdated(this.shop);

  @override
  List<Object?> get props => [shop];
}

class ShopDeleted extends ShopState {
  const ShopDeleted();
}

class ShopCreated extends ShopState {
  final ShopModel shop;

  const ShopCreated(this.shop);

  @override
  List<Object?> get props => [shop];
}

