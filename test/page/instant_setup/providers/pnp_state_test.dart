import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';

/// The two fields #1000 added to the wizard phases, and the one property each
/// is relied on for.
///
/// Both ride on `props`, and that is the point: the shell shows the save error
/// from a `ref.listen` on the phase, and Riverpod only notifies a listener when
/// the new phase is not `==` the old one. A failed save that returns to the form
/// differs from it only by `saveError`, so a `props` that left the field out
/// would make the error invisible again, which is the defect #1000 reported.
void main() {
  group('WizardConfiguring.saveError', () {
    test('is null unless given', () {
      expect(const WizardConfiguring().saveError, isNull);
    });

    test('the form with an error is a different phase', () {
      const form = WizardConfiguring();
      const failed = WizardConfiguring(saveError: TimeoutError());

      expect(failed, isNot(form));
      expect(failed, const WizardConfiguring(saveError: TimeoutError()));
    });
  });

  group('WizardYourNetwork.ready (#1511 P5)', () {
    test('two saves that wrote different credentials are different phases', () {
      // `ready` is what the completion screen shows after the firmware stage,
      // carried from the save. A `props` without it would make Your Network
      // after one save equal to Your Network after another, and Riverpod only
      // notifies a listener of a phase that is not `==` the last.
      const first = WizardYourNetwork(
        ready: WizardWifiReady(ssid: 'Home', password: 'Pass1234'),
      );
      const second = WizardYourNetwork(
        ready: WizardWifiReady(ssid: 'Home', password: 'Other5678'),
      );

      expect(second, isNot(first));
      expect(
          first,
          const WizardYourNetwork(
            ready: WizardWifiReady(ssid: 'Home', password: 'Pass1234'),
          ));
    });
  });

  group('WizardNeedsReconnect.writeUnanswered', () {
    test('defaults to false — a confirmed write has nothing left to verify',
        () {
      const phase = WizardNeedsReconnect(
        newSsid: 'Home',
        newPassword: 'Pass1234',
      );

      expect(phase.writeUnanswered, isFalse);
      expect(phase.write, isNull);
    });

    test('a write still to be verified is a different phase', () {
      // The reconnect step's Next reads this flag to decide whether to read the
      // router back; folding the two into one phase would skip that read.
      const confirmed = WizardNeedsReconnect(
        newSsid: 'Home',
        newPassword: 'Pass1234',
      );
      const unanswered = WizardNeedsReconnect(
        newSsid: 'Home',
        newPassword: 'Pass1234',
        writeUnanswered: true,
      );

      expect(unanswered, isNot(confirmed));
    });
  });
}
