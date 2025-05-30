import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/features/shop/presentation/bloc/shop_list_bloc.dart';
import 'package:user_app/features/shop/presentation/widgets/shop_card.dart';


class FeaturedShopsCarousel extends StatelessWidget {
  const FeaturedShopsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ShopListBloc, ShopListState>(
      buildWhen: (previous, current) {
        // Only rebuild for featured shop states
        return current is ShopListLoadingFeatured ||
               current is ShopListFeaturedLoaded ||
               current is ShopListFeaturedError ||
               current is ShopListInitial;
      },
      builder: (context, state) {
        print('🎯 FeaturedShopsCarousel - Current state: ${state.runtimeType}');
        
        if (state is ShopListLoadingFeatured) {
          print('📍 Showing loading for featured shops');
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        } else if (state is ShopListFeaturedError) {
          print('❌ Showing error for featured shops: ${state.message}');
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load featured shops',
                    style: theme.textTheme.bodyLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ShopListBloc>().add(
                            const ShopListLoadFeaturedEvent(),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (state is ShopListFeaturedLoaded) {
          print('✅ Showing loaded featured shops: ${state.shops.length} shops');
          if (state.shops.isEmpty) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No featured shops available',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }

          return SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.shops.length,
              itemBuilder: (context, index) {
                final shop = state.shops[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == state.shops.length - 1 ? 0 : 16,
                  ),
                  child: SizedBox(
                    width: 280,
                    child: ShopCard(
                      shop: shop,
                      onTap: () {
                        context.push('/shops/${shop.id}');
                      },
                      isFeatured: true,
                    ),
                  ),
                );
              },
            ),
          );
        }

        // Default view (initial state)
        print('🔄 Showing default loading state for featured shops');
        return SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}