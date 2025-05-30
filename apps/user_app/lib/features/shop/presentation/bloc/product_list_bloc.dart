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
  String? _currentShopId;
  String? _currentQuery;
  String? _currentCategory;

  ProductListBloc(this._shopRepository) : super(ProductListInitial()) {
    on<ProductListLoadEvent>(_onLoad);
    on<ProductListSearchEvent>(_onSearch);
    on<ProductListLoadMoreEvent>(_onLoadMore);
    on<ProductListRefreshEvent>(_onRefresh);
  }

  Future<void> _onLoad(ProductListLoadEvent event, Emitter<ProductListState> emit) async {
    print('🎬 ProductListLoadEvent triggered for shop: ${event.shopId}, category: ${event.category}');
    
    _currentPage = 1;
    _currentShopId = event.shopId;
    _currentQuery = null;
    _currentCategory = event.category;
    
    emit(ProductListLoading());
    await _loadProducts(emit);
  }

  Future<void> _onSearch(ProductListSearchEvent event, Emitter<ProductListState> emit) async {
    print('🔍 ProductListSearchEvent triggered for shop: ${event.shopId}, query: ${event.query}, category: ${event.category}');
    
    _currentPage = 1;
    _currentShopId = event.shopId;
    _currentQuery = event.query;
    _currentCategory = event.category;
    
    emit(ProductListLoading());
    await _loadProducts(emit);
  }

  Future<void> _onLoadMore(ProductListLoadMoreEvent event, Emitter<ProductListState> emit) async {
    print('📄 ProductListLoadMoreEvent triggered');
    
    if (state is ProductListLoaded) {
      _currentPage++;
      emit(ProductListLoadingMore((state as ProductListLoaded).products));
      await _loadProducts(emit);
    }
  }

  Future<void> _onRefresh(ProductListRefreshEvent event, Emitter<ProductListState> emit) async {
    print('🔄 ProductListRefreshEvent triggered for shop: ${event.shopId}');
    
    _currentPage = 1;
    _currentShopId = event.shopId;
    _currentCategory = event.category;
    await _loadProducts(emit);
  }

  Future<void> _loadProducts(Emitter<ProductListState> emit) async {
    if (emit.isDone) return;
    
    try {
      print('🔍 Loading products for shop: $_currentShopId, category: $_currentCategory');
      
      // Load products and categories concurrently
      final futures = await Future.wait([
        _shopRepository.getShopProducts(
          shopId: _currentShopId!,
          query: _currentQuery,
          category: _currentCategory,
          page: _currentPage,
          limit: 20,
        ),
        _shopRepository.getProductCategories(
          shopId: _currentShopId!,
        ),
      ]);
      
      if (emit.isDone) return;
      
      final productsResult = futures[0] as dynamic;
      final categoriesResult = futures[1] as dynamic;
      
      // Process results
      productsResult.fold(
        (failure) {
          print('❌ Products failed: ${failure.message}');
          if (!emit.isDone) {
            emit(ProductListError(failure.message));
          }
        },
        (products) {
          print('✅ Products loaded: ${products.length} products');
          
          // Process categories result
          categoriesResult.fold(
            (failure) {
              print('❌ Categories failed: ${failure.message}');
              // Still emit products even if categories fail
              if (!emit.isDone) {
                emit(ProductListLoaded(
                  products: products,
                  categories: [], // Empty categories on failure
                  hasMore: products.length >= 20,
                ));
              }
            },
            (categories) {
              print('✅ Categories loaded: ${categories.length} categories');
              
              if (!emit.isDone) {
                emit(ProductListLoaded(
                  products: products,
                  categories: categories,
                  hasMore: products.length >= 20,
                ));
              }
            },
          );
        },
      );
    } catch (e) {
      print('💥 Products exception: $e');
      if (!emit.isDone) {
        emit(ProductListError(e.toString()));
      }
    }
  }
}