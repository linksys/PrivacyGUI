import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/static_routing/models/static_route_list.dart';

import '../../../mocks/test_data/scenes/static_routing_scene_data.dart';

void main() {
  group('StaticRouteList', () {
    // The page's dirty check compares two of these, so the NAT / Dynamic
    // routing choice has to take part in it (#1100).
    test('differs when only the NAT / Dynamic routing choice differs', () {
      const nat = StaticRouteList(routes: [route1], ripEnabled: false);
      const rip = StaticRouteList(routes: [route1], ripEnabled: true);

      expect(nat == rip, isFalse);
      expect(nat, const StaticRouteList(routes: [route1], ripEnabled: false));
    });

    test('a router without the switch differs from one set to NAT', () {
      expect(
        const StaticRouteList(routes: [route1]) ==
            const StaticRouteList(routes: [route1], ripEnabled: false),
        isFalse,
      );
    });

    test('copyWith keeps what it is not given', () {
      const list = StaticRouteList(routes: [route1], ripEnabled: true);

      expect(list.copyWith(routes: const [route2]),
          const StaticRouteList(routes: [route2], ripEnabled: true));
      expect(list.copyWith(ripEnabled: false),
          const StaticRouteList(routes: [route1], ripEnabled: false));
    });
  });
}
