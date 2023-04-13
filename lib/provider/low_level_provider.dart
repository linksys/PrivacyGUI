import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/network/http/linksys_http_client.dart';
import 'package:linksys_moab/provider/temp_global_repo.dart';
import 'package:linksys_moab/repository/linksys_cloud_repository.dart';

class ProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase<Object?> provider, Object? previousValue,
      Object? newValue, ProviderContainer container) {
    print(
        'provider=$provider, preValue=$previousValue, newValue=$newValue, container=$container');
  }
}

final cloudRepositoryProvider = Provider((ref) => LinksysCloudRepository(
      httpClient: LinksysHttpClient(),
    ));

final routerRepositoryProvider = Provider((ref) => gRouterRepository);
