import 'package:flutter/cupertino.dart';
import 'package:linksys_app/localization/localization_hook.dart';

String getTimeZoneRegionName(BuildContext context, timezoneId) {
  switch (timezoneId) {
    case 'GMT0-NO-DST':
      return getAppLocalizations(context).timezone_gambia_liberia_morocco;
    case 'GST-4-NO-DST':
      return getAppLocalizations(context).timezone_armenia;
    case 'EST5-NO-DST':
      return getAppLocalizations(context).timezone_indiana_east_colombia_panama;
    case 'AEST-10':
      return getAppLocalizations(context).timezone_australia;
    case 'MST7-NO-DST':
      return getAppLocalizations(context).timezone_arizona;
    case 'PKT-5-NO-DST':
      return getAppLocalizations(context).timezone_pakistan_russia;
    case 'ALMT-6-NO-DST':
      return getAppLocalizations(context).timezone_bangladesh_russia;
    case 'AZOT1':
      return getAppLocalizations(context).timezone_azores;
    case 'BRT3':
      return getAppLocalizations(context).timezone_brazil_east_greenland;
    case 'HST10-NO-DST':
      return getAppLocalizations(context).timezone_hawaii;
    case 'CST6':
      return getAppLocalizations(context).timezone_central_time_usa_and_canada;
    case 'PST8':
      return getAppLocalizations(context).timezone_pacific_time_usa_and_canada;
    case 'JST-9-NO-DST':
      return getAppLocalizations(context).timezone_japan_korea;
    case 'EST5':
      return getAppLocalizations(context).timezone_eastern_time_usa_and_canada;
    case 'ICT-7-NO-DST':
      return getAppLocalizations(context).timezone_thailand_russia;
    case 'HKT-8-NO-DST':
      return getAppLocalizations(context)
          .timezone_china_hong_kong_australia_western;
    case 'WST11-NO-DST':
      return getAppLocalizations(context).timezone_midway_island_samoa;
    case 'FJT-12-NO-DST':
      return getAppLocalizations(context).timezone_fiji;
    case 'NZST-12':
      return getAppLocalizations(context).timezone_new_zealand;
    case 'SBT-11-NO-DST':
      return getAppLocalizations(context).timezone_solomon_islands;
    case 'CET-1':
      return getAppLocalizations(context).timezone_france_germany_italy;
    case 'MAT2-NO-DST':
      return getAppLocalizations(context).timezone_mid_atlantic;
    case 'MHT12-NO-DST':
      return getAppLocalizations(context).timezone_kwajalein;
    case 'AST-3-NO-DST':
      return getAppLocalizations(context).timezone_turkey_iraq_jordan_kuwait;
    case 'CET-1-NO-DST':
      return getAppLocalizations(context).timezone_tunisia;
    case 'ART3-NO-DST':
      return getAppLocalizations(context).timezone_guyana;
    case 'IST-05:30-NO-DST':
      return getAppLocalizations(context)
          .timezone_mumbai_kolkata_chennai_new_delhi;
    case 'VET4-NO-DST':
      return getAppLocalizations(context).timezone_bolivia_venezuela;
    case 'GMT0':
      return getAppLocalizations(context).timezone_england;
    case 'SAST-2-NO-DST':
      return getAppLocalizations(context).timezone_south_africa;
    case 'AKST9':
      return getAppLocalizations(context).timezone_alaska;
    case 'MST7':
      return getAppLocalizations(context).timezone_mountain_time_usa_and_canada;
    case 'CLT4':
      return getAppLocalizations(context).timezone_chile_time_chile_antarctica;
    case 'AST4':
      return getAppLocalizations(context)
          .timezone_atlantic_time_canada_greenland_atlantic_islands;
    case 'NST03:30':
      return getAppLocalizations(context).timezone_newfoundland;
    case 'EET-2':
      return getAppLocalizations(context).timezone_greece_ukraine_romania;
    case 'GST-10-NO-DST':
      return getAppLocalizations(context).timezone_guam_russia;
    case 'CST6-NO-DST':
      return getAppLocalizations(context).timezone_mexico;
    case 'SGT-8':
    case 'SGT-8-NO-DST':
      return getAppLocalizations(context).timezone_singapore_taiwan_russia;
    default:
      return '';
  }
}

String getTimezoneGMT(String description) {
  return RegExp(r'\(([^)]+)\)').matchAsPrefix(description)?.group(1) ?? '';
}
