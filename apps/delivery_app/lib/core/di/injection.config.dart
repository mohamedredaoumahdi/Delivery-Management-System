// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:delivery_app/features/auth/presentation/bloc/auth_bloc.dart'
    as _i74;
import 'package:delivery_app/features/dashboard/presentation/bloc/dashboard_bloc.dart'
    as _i195;
import 'package:delivery_app/features/earnings/presentation/bloc/earnings_bloc.dart'
    as _i255;
import 'package:delivery_app/features/location/presentation/bloc/location_bloc.dart'
    as _i828;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<_i74.AuthBloc>(() => _i74.AuthBloc());
    gh.factory<_i828.LocationBloc>(() => _i828.LocationBloc());
    gh.factory<_i195.DashboardBloc>(() => _i195.DashboardBloc());
    gh.factory<_i255.EarningsBloc>(() => _i255.EarningsBloc());
    return this;
  }
}
