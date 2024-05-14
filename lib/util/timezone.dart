import 'package:flutter/cupertino.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

String getTimeZoneRegionName(BuildContext context, timezoneId) {
  switch (timezoneId) {
    case 'GMT0-NO-DST':
      return getAppLocalizations(context).timezoneGambiaLiberiaMorocco;
    case 'GST-4-NO-DST':
      return getAppLocalizations(context).timezoneArmenia;
    case 'EST5-NO-DST':
      return getAppLocalizations(context).timezoneIndianaEastColombiaPanama;
    case 'AEST-10':
      return getAppLocalizations(context).timezoneAustralia;
    case 'MST7-NO-DST':
      return getAppLocalizations(context).timezoneArizona;
    case 'PKT-5-NO-DST':
      return getAppLocalizations(context).timezonePakistanRussia;
    case 'ALMT-6-NO-DST':
      return getAppLocalizations(context).timezoneBangladeshRussia;
    case 'AZOT1':
      return getAppLocalizations(context).timezoneAzores;
    case 'BRT3':
      return getAppLocalizations(context).timezoneBrazilEastGreenland;
    case 'HST10-NO-DST':
      return getAppLocalizations(context).timezoneHawaii;
    case 'CST6':
      return getAppLocalizations(context).timezoneCentralTimeUsaAndCanada;
    case 'PST8':
      return getAppLocalizations(context).timezonePacificTimeUsaAndCanada;
    case 'JST-9-NO-DST':
      return getAppLocalizations(context).timezoneJapanKorea;
    case 'EST5':
      return getAppLocalizations(context).timezoneEasternTimeUsaAndCanada;
    case 'ICT-7-NO-DST':
      return getAppLocalizations(context).timezoneThailandRussia;
    case 'HKT-8-NO-DST':
      return getAppLocalizations(context).timezoneChinaHongKongAustraliaWestern;
    case 'WST11-NO-DST':
      return getAppLocalizations(context).timezoneMidwayIslandSamoa;
    case 'FJT-12-NO-DST':
      return getAppLocalizations(context).timezoneFiji;
    case 'NZST-12':
      return getAppLocalizations(context).timezoneNewZealand;
    case 'SBT-11-NO-DST':
      return getAppLocalizations(context).timezoneSolomonIslands;
    case 'CET-1':
      return getAppLocalizations(context).timezoneFranceGermanyItaly;
    case 'MAT2-NO-DST':
      return getAppLocalizations(context).timezoneMidAtlantic;
    case 'MHT12-NO-DST':
      return getAppLocalizations(context).timezoneKwajalein;
    case 'AST-3-NO-DST':
      return getAppLocalizations(context).timezoneTurkeyIraqJordanKuwait;
    case 'CET-1-NO-DST':
      return getAppLocalizations(context).timezoneTunisia;
    case 'ART3-NO-DST':
      return getAppLocalizations(context).timezoneGuyana;
    case 'IST-05:30-NO-DST':
      return getAppLocalizations(context).timezoneMumbaiKolkataChennaiNewDelhi;
    case 'VET4-NO-DST':
      return getAppLocalizations(context).timezoneBoliviaVenezuela;
    case 'GMT0':
      return getAppLocalizations(context).timezoneEngland;
    case 'SAST-2-NO-DST':
      return getAppLocalizations(context).timezoneSouthAfrica;
    case 'AKST9':
      return getAppLocalizations(context).timezoneAlaska;
    case 'MST7':
      return getAppLocalizations(context).timezoneMountainTimeUsaAndCanada;
    case 'CLT4':
      return getAppLocalizations(context).timezoneChileTimeChileAntarctica;
    case 'AST4':
      return getAppLocalizations(context)
          .timezoneAtlanticTimeCanadaGreenlandAtlanticIslands;
    case 'NST03:30':
      return getAppLocalizations(context).timezoneNewfoundland;
    case 'EET-2':
      return getAppLocalizations(context).timezoneGreeceUkraineRomania;
    case 'GST-10-NO-DST':
      return getAppLocalizations(context).timezoneGuamRussia;
    case 'CST6-NO-DST':
      return getAppLocalizations(context).timezoneMexico;
    case 'SGT-8':
    case 'SGT-8-NO-DST':
      return getAppLocalizations(context).timezoneSingaporeTaiwanRussia;
    default:
      return '';
  }
}

String getTimezoneGMT(String description) {
  return RegExp(r'\(([^)]+)\)').matchAsPrefix(description)?.group(1) ?? '';
}
