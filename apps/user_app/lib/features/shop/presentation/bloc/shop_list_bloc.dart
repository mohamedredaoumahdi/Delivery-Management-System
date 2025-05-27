import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'shop_list_event.dart';
part 'shop_list_state.dart';

class ShopListBloc extends Bloc<ShopListEvent, ShopListState> {
  final ShopRepository _shopRepository;

  ShopListBloc({
    required ShopRepository shopRepository,
  }) : _shopRepository = shopRepository,
       super(const ShopListInitial()) {
    on<ShopListLoadEvent>(_onShopListLoad);
    on<ShopListSearchEvent>(_onShopListSearch);
    on<ShopListFilterByCategoryEvent>(_onShopListFilterByCategory);
    on<ShopListLoadMoreEvent>(_onShopListLoadMore);
    on<ShopListRefreshEvent>(_onShopListRefresh);
    on<ShopListLoadFeaturedEvent>(_onShopListLoadFeatured);
    on<ShopListLoadNearbyEvent>(_onShopListLoadNearby);
  }

  Future<void> _onShopListLoad(
    ShopListLoadEvent event,
    Emitter<ShopListState> emit,
  ) async {
    emit(const ShopListLoading());

    try {
      final result = await _shopRepository.getShops(
        category: event.category,
        page: 1,
        limit: 10,
      );

      result.fold(
        (failure) => emit(ShopListError(failure.message)),
        (shops) => emit(ShopListLoaded(
          shops: shops,
          hasMore: shops.length >= 10, // Assuming there might be more if we reached the limit
          currentPage: 1,
          category: event.category,
          searchQuery: null,
        )),
      );
    } catch (e) {
      emit(ShopListError(e.toString()));
    }
  }

  Future<void> _onShopListSearch(
    ShopListSearchEvent event,
    Emitter<ShopListState> emit,
  ) async {
    emit(const ShopListLoading());

    try {
      final result = await _shopRepository.getShops(
        query: event.query,
        category: event.category,
        page: 1,
        limit: 10,
      );

      result.fold(
        (failure) => emit(ShopListError(failure.message)),
        (shops) => emit(ShopListLoaded(
          shops: shops,
          hasMore: shops.length >= 10,
          currentPage: 1,
          category: event.category,
          searchQuery: event.query,
        )),
      );
    } catch (e) {
      emit(ShopListError(e.toString()));
    }
  }

  Future<void> _onShopListFilterByCategory(
    ShopListFilterByCategoryEvent event,
    Emitter<ShopListState> emit,
  ) async {
    emit(const ShopListLoading());

    try {
      final result = await _shopRepository.getShops(
        category: event.category,
        page: 1,
        limit: 10,
      );

      result.fold(
        (failure) => emit(ShopListError(failure.message)),
        (shops) => emit(ShopListLoaded(
          shops: shops,
          hasMore: shops.length >= 10,
          currentPage: 1,
          category: event.category,
          searchQuery: null,
        )),
      );
    } catch (e) {
      emit(ShopListError(e.toString()));
    }
  }

  Future<void> _onShopListLoadMore(
    ShopListLoadMoreEvent event,
    Emitter<ShopListState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is ShopListLoaded && currentState.hasMore) {
      emit(ShopListLoadingMore(
        shops: currentState.shops,
        currentPage: currentState.currentPage,
        category: currentState.category,
        searchQuery: currentState.searchQuery,
      ));

      try {
        final nextPage = currentState.currentPage + 1;
        
        final result = await _shopRepository.getShops(
          query: currentState.searchQuery,
          category: currentState.category,
          page: nextPage,
          limit: 10,
        );

        result.fold(
          (failure) => emit(ShopListError(failure.message)),
          (newShops) {
            final allShops = [...currentState.shops, ...newShops];
            
            emit(ShopListLoaded(
              shops: allShops,
              hasMore: newShops.length >= 10,
              currentPage: nextPage,
              category: currentState.category,
              searchQuery: currentState.searchQuery,
            ));
          },
        );
      } catch (e) {
        emit(ShopListError(e.toString()));
      }
    }
  }

  Future<void> _onShopListRefresh(
    ShopListRefreshEvent event,
    Emitter<ShopListState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is ShopListLoaded) {
      emit(ShopListLoading(
        oldShops: currentState.shops,
      ));

      try {
        final result = await _shopRepository.getShops(
          query: currentState.searchQuery,
          category: currentState.category,
          page: 1,
          limit: 10,
        );

        result.fold(
          (failure) => emit(ShopListError(failure.message)),
          (shops) => emit(ShopListLoaded(
            shops: shops,
            hasMore: shops.length >= 10,
            currentPage: 1,
            category: currentState.category,
            searchQuery: currentState.searchQuery,
          )),
        );
      } catch (e) {
        emit(ShopListError(e.toString()));
      }
    } else {
      add(const ShopListLoadEvent());
    }
  }

  Future<void> _onShopListLoadFeatured(
    ShopListLoadFeaturedEvent event,
    Emitter<ShopListState> emit,
  ) async {
    emit(const ShopListLoadingFeatured());

    try {
      print('🔍 Loading featured shops with limit: ${event.limit}');
      final result = await _shopRepository.getFeaturedShops(limit: event.limit);

      result.fold(
        (failure) {
          print('❌ Featured shops failed: ${failure.message}');
          emit(ShopListFeaturedError(failure.message));
        },
        (shops) {
          print('✅ Featured shops loaded: ${shops.length} shops');
          for (final shop in shops) {
            print('  - ${shop.name} (${shop.id})');
          }
          emit(ShopListFeaturedLoaded(shops: shops));
        },
      );
    } catch (e) {
      print('💥 Featured shops exception: $e');
      emit(ShopListFeaturedError(e.toString()));
    }
  }

  Future<void> _onShopListLoadNearby(
    ShopListLoadNearbyEvent event,
    Emitter<ShopListState> emit,
  ) async {
    emit(const ShopListLoadingNearby());

    try {
      final result = await _shopRepository.getNearbyShops(
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
        limit: event.limit,
      );

      result.fold(
        (failure) => emit(ShopListNearbyError(failure.message)),
        (shops) => emit(ShopListNearbyLoaded(shops: shops)),
      );
    } catch (e) {
      emit(ShopListNearbyError(e.toString()));
    }
  }
}