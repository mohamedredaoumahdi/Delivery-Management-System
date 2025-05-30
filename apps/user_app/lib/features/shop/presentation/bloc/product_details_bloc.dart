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
    print('🚀 ProductDetailsLoadEvent triggered for product: ${event.productId}');
    
    if (emit.isDone) {
      print('❌ ProductDetails _onLoad aborted - emit is already done');
      return;
    }
    
    emit(ProductDetailsLoading());
    
    try {
      print('🔍 Loading product with shop details for: ${event.productId}');
      
      final result = await _shopRepository.getProductWithShop(event.productId);
      
      if (emit.isDone) {
        print('⚠️ Emit is done after loading, cannot continue');
        return;
      }
      
      result.fold(
        (failure) {
          print('❌ Product with shop loading failed: ${failure.message}');
          if (!emit.isDone) {
            emit(ProductDetailsError(failure.message));
          }
        },
        (data) {
          final (product, shop) = data;
          print('✅ Product and shop loaded: ${product.name} from ${shop.name}');
          if (!emit.isDone) {
            emit(ProductDetailsLoaded(product, shop));
            print('🎯 ProductDetailsLoaded state emitted successfully');
          }
        },
      );
    } catch (e) {
      print('❌ ProductDetails exception: $e');
      if (!emit.isDone) {
        emit(ProductDetailsError(e.toString()));
      }
    }
  }
}