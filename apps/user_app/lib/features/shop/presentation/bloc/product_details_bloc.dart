import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class ProductDetailsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductDetailsLoadEvent extends ProductDetailsEvent {
  final String productId;
  ProductDetailsLoadEvent(this.productId);
  
  @override
  List<Object?> get props => [productId];
}

// States
abstract class ProductDetailsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductDetailsInitial extends ProductDetailsState {}
class ProductDetailsLoading extends ProductDetailsState {}
class ProductDetailsLoaded extends ProductDetailsState {
  final Product product;
  final Shop shop;
  ProductDetailsLoaded(this.product, this.shop);
  
  @override
  List<Object?> get props => [product, shop];
}
class ProductDetailsError extends ProductDetailsState {
  final String message;
  ProductDetailsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class ProductDetailsBloc extends Bloc<ProductDetailsEvent, ProductDetailsState> {
  final ShopRepository _shopRepository;

  ProductDetailsBloc(this._shopRepository) : super(ProductDetailsInitial()) {
    on<ProductDetailsLoadEvent>(_onLoad);
  }

  Future<void> _onLoad(ProductDetailsLoadEvent event, Emitter<ProductDetailsState> emit) async {
    emit(ProductDetailsLoading());
    try {
      final result = await _shopRepository.getProductById(event.productId);
      result.fold(
        (failure) => emit(ProductDetailsError(failure.message)),
        (product) async {
          final shopResult = await _shopRepository.getShopById(product.shopId);
          shopResult.fold(
            (failure) => emit(ProductDetailsError(failure.message)),
            (shop) => emit(ProductDetailsLoaded(product, shop)),
          );
        },
      );
    } catch (e) {
      emit(ProductDetailsError(e.toString()));
    }
  }
}