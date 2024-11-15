import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/power_table_settings.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/consts.dart';
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';

enum PowerTableCountries {
  chn,
  hkg,
  ind,
  idn,
  jpn,
  kor,
  phl,
  sgp,
  twn,
  tha,
  xah,
  aus,
  can,
  eee,
  lam,
  bhr,
  egy,
  kwt,
  omn,
  qat,
  sau,
  tur,
  are,
  xme,
  nzl,
  usa,
  ;

  resolveDisplayText(BuildContext context) => switch (this) {
        PowerTableCountries.chn => loc(context).asiaChina,
        PowerTableCountries.hkg => loc(context).asiaHongkong,
        PowerTableCountries.ind => loc(context).asiaIndia,
        PowerTableCountries.idn => loc(context).asiaIndonesia,
        PowerTableCountries.jpn => loc(context).asiaJapan,
        PowerTableCountries.kor => loc(context).asiaKorea,
        PowerTableCountries.phl => loc(context).asiaPhilippines,
        PowerTableCountries.sgp => loc(context).asiaSingapore,
        PowerTableCountries.twn => loc(context).asiaTaiwan,
        PowerTableCountries.tha => loc(context).asiaThailand,
        PowerTableCountries.xah => loc(context).asiaRest,
        PowerTableCountries.aus => loc(context).australia,
        PowerTableCountries.can => loc(context).canada,
        PowerTableCountries.eee => loc(context).europe,
        PowerTableCountries.lam => loc(context).latinAmerica,
        PowerTableCountries.bhr => loc(context).middleEastBahrain,
        PowerTableCountries.egy => loc(context).middleEastEgypt,
        PowerTableCountries.kwt => loc(context).middleEastKuwait,
        PowerTableCountries.omn => loc(context).middleEastOman,
        PowerTableCountries.qat => loc(context).middleEastQatar,
        PowerTableCountries.sau => loc(context).middleEastSaudiArabia,
        PowerTableCountries.tur => loc(context).middleEastTurkey,
        PowerTableCountries.are => loc(context).middleEastUnitedArabEmirates,
        PowerTableCountries.xme => loc(context).middleEast,
        PowerTableCountries.nzl => loc(context).newZealand,
        PowerTableCountries.usa => loc(context).unitedState,
      };

  int compareTo(PowerTableCountries other) => index - other.index;

  static PowerTableCountries resolve(String country) => switch (country) {
        'CHN' => PowerTableCountries.chn,
        'HKG' => PowerTableCountries.hkg,
        'IND' => PowerTableCountries.ind,
        'IDN' => PowerTableCountries.idn,
        'JPN' => PowerTableCountries.jpn,
        'KOR' => PowerTableCountries.kor,
        'PHL' => PowerTableCountries.phl,
        'SGP' => PowerTableCountries.sgp,
        'TWN' => PowerTableCountries.twn,
        'THA' => PowerTableCountries.tha,
        'XAH' => PowerTableCountries.xah,
        'AUS' => PowerTableCountries.aus,
        'CAN' => PowerTableCountries.can,
        'EEE' => PowerTableCountries.eee,
        'LAM' => PowerTableCountries.lam,
        'BHR' => PowerTableCountries.bhr,
        'EGY' => PowerTableCountries.egy,
        'KWT' => PowerTableCountries.kwt,
        'OMN' => PowerTableCountries.omn,
        'QAT' => PowerTableCountries.qat,
        'SAU' => PowerTableCountries.sau,
        'TUR' => PowerTableCountries.tur,
        'ARE' => PowerTableCountries.are,
        'XME' => PowerTableCountries.xme,
        'NZL' => PowerTableCountries.nzl,
        'USA' => PowerTableCountries.usa,
        _ => PowerTableCountries.usa,
      };
}

final powerTableProvider =
    NotifierProvider<PowerTableNotifier, PowerTableState>(
        () => PowerTableNotifier());

class PowerTableNotifier extends Notifier<PowerTableState> {
  @override
  PowerTableState build() {
    final results = ref.watch(pollingProvider).value?.data ?? {};

    final powerTableSettings = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getPowerTableSettings, results);
    if (powerTableSettings == null) {
      return PowerTableState(
          isPowerTableSelectable: false, supportedCountries: const []);
    }
    final powerTable = PowerTableSettings.fromMap(powerTableSettings.output);
    return PowerTableState(
        isPowerTableSelectable: powerTable.isPowerTableSelectable,
        supportedCountries: List.from(
          powerTable.supportedCountries.map(
            (e) => PowerTableCountries.resolve(e),
          ),
        )..sort((a, b) => a.compareTo(b)),
        country: PowerTableCountries.resolve(powerTable.country ?? ''));
  }

  Future<PowerTableState> save(PowerTableCountries country) {
    ref.read(pollingProvider.notifier).stopPolling();
    return ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.setPowerTableSettings,
          data: {'country': country.name.toUpperCase()},
          auth: true,
        )
        .then((_) => ref.read(pollingProvider.notifier).startPolling())
        .then((_) => ref.read(pollingProvider.notifier).forcePolling())
        .then(
          (_) => state.copyWith(country: country),
        );
  }
}
