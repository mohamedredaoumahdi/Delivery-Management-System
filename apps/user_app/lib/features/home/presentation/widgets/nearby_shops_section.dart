import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';

import '../../shop/presentation/bloc/shop_list_bloc.dart';
import '../../shop/presentation/widgets/shop_list_item.dart';

class NearbyShopsSection extends StatelessWidget {
  const NearbyShopsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ShopListBloc, ShopListState>(
      builder: (context, state) {
        if (state is ShopListLoadingNearby) {
          return SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        } else if (state is ShopListNearbyError) {
          return SizedBox(
            height: 120,
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
                    'Failed to load nearby shops',
                    style: theme.textTheme.bodyLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ShopListBloc>().add(
                            const ShopListLoadNearbyEvent(
                              latitude: 37.7749, // Default to San Francisco
                              longitude: -122.4194,
                            ),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (state is ShopListNearbyLoaded) {
          if (state.shops.isEmpty) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No shops found nearby',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.shops.length > 3 ? 3 : state.shops.length, // Show max 3 shops
            itemBuilder: (context, index) {
              final shop = state.shops[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShopListItem(
                  shop: shop,
                  onTap: () {
                    context.push('/shops/${shop.id}');
                  },
                ),
              );
            },
          );
        }

        // Default view (initial state)
        return SizedBox(
          height: 120,
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