import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/shop_service.dart';
import '../../data/models/shop_model.dart';
import 'shop_event.dart';
import 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final ShopService shopService;

  ShopBloc({required this.shopService}) : super(const ShopInitial()) {
    on<LoadShops>(_onLoadShops);
    on<RefreshShops>(_onRefreshShops);
    on<LoadShopDetails>(_onLoadShopDetails);
    on<CreateShop>(_onCreateShop);
    on<UpdateShop>(_onUpdateShop);
    on<DeleteShop>(_onDeleteShop);
    on<FilterShops>(_onFilterShops);
  }

  Future<void> _onLoadShops(LoadShops event, Emitter<ShopState> emit) async {
    emit(const ShopLoading());
    try {
      final shops = await shopService.getShops();
      emit(ShopsLoaded(
        shops: shops,
        filteredShops: shops,
        selectedCategory: null,
        selectedStatus: null,
        searchQuery: null,
      ));
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onRefreshShops(RefreshShops event, Emitter<ShopState> emit) async {
    try {
      final shops = await shopService.getShops();
      if (state is ShopsLoaded) {
        final currentState = state as ShopsLoaded;
        final filteredShops = _applyFilters(
          shops,
          category: currentState.selectedCategory,
          searchQuery: currentState.searchQuery,
          isActive: currentState.selectedStatus,
        );
        emit(ShopsLoaded(
          shops: shops,
          filteredShops: filteredShops,
          selectedCategory: currentState.selectedCategory,
          selectedStatus: currentState.selectedStatus,
          searchQuery: currentState.searchQuery,
        ));
      } else {
        emit(ShopsLoaded(
          shops: shops,
          filteredShops: shops,
          selectedCategory: null,
          selectedStatus: null,
          searchQuery: null,
        ));
      }
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onLoadShopDetails(LoadShopDetails event, Emitter<ShopState> emit) async {
    emit(const ShopLoading());
    try {
      final shop = await shopService.getShopById(event.shopId);
      emit(ShopDetailsLoaded(shop));
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onCreateShop(CreateShop event, Emitter<ShopState> emit) async {
    try {
      final shop = await shopService.createShop(event.data);
      emit(ShopCreated(shop));
      
      // Reload shops list and preserve filters
      final shops = await shopService.getShops();
      if (state is ShopsLoaded) {
        final currentState = state as ShopsLoaded;
        final filteredShops = _applyFilters(
          shops,
          category: currentState.selectedCategory,
          searchQuery: currentState.searchQuery,
          isActive: currentState.selectedStatus,
        );
        emit(ShopsLoaded(
          shops: shops,
          filteredShops: filteredShops,
          selectedCategory: currentState.selectedCategory,
          selectedStatus: currentState.selectedStatus,
          searchQuery: currentState.searchQuery,
        ));
      } else {
        emit(ShopsLoaded(
          shops: shops,
          filteredShops: shops,
          selectedCategory: null,
          selectedStatus: null,
          searchQuery: null,
        ));
      }
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onUpdateShop(UpdateShop event, Emitter<ShopState> emit) async {
    try {
      final updatedShop = await shopService.updateShop(event.shopId, event.data);
      emit(ShopUpdated(updatedShop));
      
      // Reload shops list and preserve filters
      final shops = await shopService.getShops();
      if (state is ShopsLoaded) {
        final currentState = state as ShopsLoaded;
        final filteredShops = _applyFilters(
          shops,
          category: currentState.selectedCategory,
          searchQuery: currentState.searchQuery,
          isActive: currentState.selectedStatus,
        );
        emit(ShopsLoaded(
          shops: shops,
          filteredShops: filteredShops,
          selectedCategory: currentState.selectedCategory,
          selectedStatus: currentState.selectedStatus,
          searchQuery: currentState.searchQuery,
        ));
      } else {
        emit(ShopsLoaded(
          shops: shops,
          filteredShops: shops,
          selectedCategory: null,
          selectedStatus: null,
          searchQuery: null,
        ));
      }
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onDeleteShop(DeleteShop event, Emitter<ShopState> emit) async {
    try {
      await shopService.deleteShop(event.shopId);
      emit(const ShopDeleted());
      
      // Reload shops list and preserve filters
      final shops = await shopService.getShops();
      if (state is ShopsLoaded) {
        final currentState = state as ShopsLoaded;
        final filteredShops = _applyFilters(
          shops,
          category: currentState.selectedCategory,
          searchQuery: currentState.searchQuery,
          isActive: currentState.selectedStatus,
        );
        emit(ShopsLoaded(
          shops: shops,
          filteredShops: filteredShops,
          selectedCategory: currentState.selectedCategory,
          selectedStatus: currentState.selectedStatus,
          searchQuery: currentState.searchQuery,
        ));
      } else {
        emit(ShopsLoaded(
          shops: shops,
          filteredShops: shops,
          selectedCategory: null,
          selectedStatus: null,
          searchQuery: null,
        ));
      }
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  void _onFilterShops(FilterShops event, Emitter<ShopState> emit) {
    if (state is ShopsLoaded) {
      final currentState = state as ShopsLoaded;
      final filteredShops = _applyFilters(
        currentState.shops,
        category: event.category,
        searchQuery: event.searchQuery,
        isActive: event.isActive,
      );
      emit(ShopsLoaded(
        shops: currentState.shops,
        filteredShops: filteredShops,
        selectedCategory: event.category,
        selectedStatus: event.isActive,
        searchQuery: event.searchQuery,
      ));
    }
  }

  List<ShopModel> _applyFilters(
    List<ShopModel> shops, {
    String? category,
    String? searchQuery,
    bool? isActive,
  }) {
    var filtered = List<ShopModel>.from(shops);

    // Apply category filter
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((shop) => shop.category == category).toList();
    }

    // Apply active status filter
    if (isActive != null) {
      filtered = filtered.where((shop) => shop.isActive == isActive).toList();
    }

    // Apply search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((shop) {
        final name = shop.name.toLowerCase();
        final description = shop.description.toLowerCase();
        final address = shop.address.toLowerCase();
        final email = shop.email.toLowerCase();
        final phone = shop.phone.toLowerCase();
        
        return name.contains(query) ||
            description.contains(query) ||
            address.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      }).toList();
    }

    return filtered;
  }
}

