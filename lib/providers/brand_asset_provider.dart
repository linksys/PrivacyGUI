import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/utils.dart';

final brandAssetProvider =
    FutureProvider.family<String?, ({String modelNumber, BrandAsset asset})>(
        (ref, arg) async {
  return BrandUtils.getAssetPath(arg.modelNumber, arg.asset);
});
