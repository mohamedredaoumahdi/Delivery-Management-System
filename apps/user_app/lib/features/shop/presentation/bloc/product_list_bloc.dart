// apps/user_app/lib/features/shop/presentation/bloc/product_list_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class ProductListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductListLoadEvent extends ProductListEvent {
  final String shopId;
  final String? category;
  ProductListLoadEvent({required this.shopId, this.category});
  
  @override
  List<Object?> get props => [shopId, category];
}

class ProductListSearchEvent extends ProductListEvent {
  final String shopId;
  final String query;
  final String? category;
  ProductListSearchEvent({
    required this.shopId,
    required this.query,
    this.category,
  });
  
  @override
  List<Object?> get props => [shopId, query, category];
}

class ProductListLoadMoreEvent extends ProductListEvent {}

class ProductListRefreshEvent extends ProductListEvent {
  final String shopId;
  final String? category;
  ProductListRefreshEvent({required this.shopId, this.category});
  
  @override
  List<Object?> get props => [shopId, category];
}

// States
abstract class ProductListState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductListInitial extends ProductListState {}
class ProductListLoading extends ProductListState {
  final List<Product>? oldProducts;
  ProductListLoading({this.oldProducts});
  
  @override
  List<Object?> get props => [oldProducts];
}
class ProductListLoaded extends ProductListState {
  final List<Product> products;
  final List<String> categories;
  final bool hasMore;
  ProductListLoaded({
    required this.products,
    required this.categories,
    this.hasMore = false,
  });
  
  @override
  List<Object?> get props => [products, categories, hasMore];
}
class ProductListLoadingMore extends ProductListState {
  final List<Product> products;
  ProductListLoadingMore(this.products);
  
  @override
  List<Object?> get props => [products];
}
class ProductListError extends ProductListState {
  final String message;
  ProductListError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final ShopRepository _shopRepository;
  int _currentPage = 1;
  String? _currentQuery;
  String? _currentCategory;

  ProductListBloc(this._shopRepository) : super(ProductListInitial()) {
    on<ProductListLoadEvent>(_onLoad);
    on<ProductListSearchEvent>(_onSearch);
    on<ProductListLoadMoreEvent>(_onLoadMore);
    on<ProductListRefreshEvent>(_onRefresh);
  }

  Future<void> _onLoad(ProductListLoadEvent event, Emitter<ProductListState> emit) async {
    _currentPage = 1;
    _currentQuery = null;
    _currentCategory = event.category;
    
    emit(ProductListLoading());
    await _loadProducts(emit);
  }

  Future<void> _onSearch(ProductListSearchEvent event, Emitter<ProductListState> emit) async {
    _currentPage = 1;
    _currentQuery = event.query;
    _currentCategory = event.category;
    
    emit(ProductListLoading());
    await _loadProducts(emit);
  }

  Future<void> _onLoadMore(ProductListLoadMoreEvent event, Emitter<ProductListState> emit) async {
    if (state is ProductListLoaded) {
      _currentPage++;
      emit(ProductListLoadingMore((state as ProductListLoaded).products));
      await _loadProducts(emit);
    }
  }

  Future<void> _onRefresh(ProductListRefreshEvent event, Emitter<ProductListState> emit) async {
    _currentPage = 1;
    _currentCategory = event.category;
    await _loadProducts(emit);
  }

  Future<void> _loadProducts(Emitter<ProductListState> emit) async {
    try {
      final result = await _shopRepository.getShopProducts(
        shopId: _currentQuery == null ? _currentCategory! : _currentQuery!,
        page: _currentPage,
        limit: 20,
      );
      
      result.fold(
        (failure) => emit(ProductListError(failure.message)),
        (products) async {
          final categoriesResult = await _shopRepository.getProductCategories(
            shopId: _currentQuery == null ? _currentCategory! : _currentQuery!,
          );
          
          categoriesResult.fold(
            (failure) => emit(ProductListError(failure.message)),
            (categories) => emit(ProductListLoaded(
              products: products,
              categories: categories,
              hasMore: products.length >= 20,
            )),
          );
        },
      );
    } catch (e) {
      emit(ProductListError(e.toString()));
    }
  }
}