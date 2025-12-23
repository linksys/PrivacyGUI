import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';
import 'package:privacy_gui/page/instant_admin/services/power_table_service.dart';

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
        PowerTableCountries.aus =>
          '${loc(context).australia}/${loc(context).newZealand}',
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
        PowerTableCountries.nzl =>
          '${loc(context).australia}/${loc(context).newZealand}',
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
    final service = ref.read(powerTableServiceProvider);
    final pollingData = ref.watch(pollingProvider).value?.data ?? {};

    final powerTableState = service.parsePowerTableSettings(pollingData);
    if (powerTableState == null) {
      return PowerTableState(
        isPowerTableSelectable: false,
        supportedCountries: const [],
      );
    }

    return powerTableState;
  }

  Future<PowerTableState> save(PowerTableCountries country) async {
    final service = ref.read(powerTableServiceProvider);

    ref.read(pollingProvider.notifier).stopPolling();
    await service.savePowerTableCountry(country);
    await ref.read(pollingProvider.notifier).startPolling();
    await ref.read(pollingProvider.notifier).forcePolling();

    return state.copyWith(country: country);
  }
}
