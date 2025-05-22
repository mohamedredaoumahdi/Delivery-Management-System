import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';

import '../../shop/presentation/bloc/shop_list_bloc.dart';
import '../../shop/presentation/widgets/shop_card.dart';

class FeaturedShopsCarousel extends StatelessWidget {
  const FeaturedShopsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ShopListBloc, ShopListState>(
      builder: (context, state) {
        if (state is ShopListLoadingFeatured) {
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        } else if (state is ShopListFeaturedError) {
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
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
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