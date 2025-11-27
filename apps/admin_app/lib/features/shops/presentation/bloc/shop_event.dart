import 'package:equatable/equatable.dart';

abstract class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object?> get props => [];
}

class LoadShops extends ShopEvent {
  const LoadShops();
}

class CreateShop extends ShopEvent {
  final Map<String, dynamic> data;

  const CreateShop(this.data);

  @override
  List<Object?> get props => [data];
}

class RefreshShops extends ShopEvent {
  const RefreshShops();
}

class LoadShopDetails extends ShopEvent {
  final String shopId;

  const LoadShopDetails(this.shopId);

  @override
  List<Object?> get props => [shopId];
}

class UpdateShop extends ShopEvent {
  final String shopId;
  final Map<String, dynamic> data;

  const UpdateShop(this.shopId, this.data);

  @override
  List<Object?> get props => [shopId, data];
}

class DeleteShop extends ShopEvent {
  final String shopId;

  const DeleteShop(this.shopId);

  @override
  List<Object?> get props => [shopId];
}

class FilterShops extends ShopEvent {
  final String? category;
  final String? searchQuery;
  final bool? isActive;

  const FilterShops({this.category, this.searchQuery, this.isActive});

  @override
  List<Object?> get props => [category, searchQuery, isActive];
}

