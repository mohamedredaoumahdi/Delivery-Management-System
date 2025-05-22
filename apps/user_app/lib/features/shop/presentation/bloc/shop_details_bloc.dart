// apps/user_app/lib/features/shop/presentation/bloc/shop_details_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class ShopDetailsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ShopDetailsLoadEvent extends ShopDetailsEvent {
  final String shopId;
  ShopDetailsLoadEvent(this.shopId);
  
  @override
  List<Object?> get props => [shopId];
}

// States
abstract class ShopDetailsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ShopDetailsInitial extends ShopDetailsState {}
class ShopDetailsLoading extends ShopDetailsState {}
class ShopDetailsLoaded extends ShopDetailsState {
  final Shop shop;
  ShopDetailsLoaded(this.shop);
  
  @override
  List<Object?> get props => [shop];
}
class ShopDetailsError extends ShopDetailsState {
  final String message;
  ShopDetailsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class ShopDetailsBloc extends Bloc<ShopDetailsEvent, ShopDetailsState> {
  final ShopRepository _shopRepository;

  ShopDetailsBloc(this._shopRepository) : super(ShopDetailsInitial()) {
    on<ShopDetailsLoadEvent>(_onLoad);
  }

  Future<void> _onLoad(ShopDetailsLoadEvent event, Emitter<ShopDetailsState> emit) async {
    emit(ShopDetailsLoading());
    try {
      final result = await _shopRepository.getShopById(event.shopId);
      result.fold(
        (failure) => emit(ShopDetailsError(failure.message)),
        (shop) => emit(ShopDetailsLoaded(shop)),
      );
    } catch (e) {
      emit(ShopDetailsError(e.toString()));
    }
  }
}