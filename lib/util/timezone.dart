import 'package:flutter/cupertino.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

String getTimeZoneRegionName(BuildContext context, timezoneId) {
  switch (timezoneId) {
    case 'GMT0-NO-DST':
      return loc(context).timezoneGambiaLiberiaMorocco;
    case 'GST-4-NO-DST':
      return loc(context).timezoneArmenia;
    case 'EST5-NO-DST':
      return loc(context).timezoneIndianaEastColombiaPanama;
    case 'AEST-10':
      return loc(context).timezoneAustralia;
    case 'MST7-NO-DST':
      return loc(context).timezoneArizona;
    case 'PKT-5-NO-DST':
      return loc(context).timezonePakistanRussia;
    case 'ALMT-6-NO-DST':
      return loc(context).timezoneBangladeshRussia;
    case 'AZOT1':
      return loc(context).timezoneAzores;
    case 'BRT3':
      return loc(context).timezoneBrazilEastGreenland;
    case 'HST10-NO-DST':
      return loc(context).timezoneHawaii;
    case 'CST6':
      return loc(context).timezoneCentralTimeUsaAndCanada;
    case 'PST8':
      return loc(context).timezonePacificTimeUsaAndCanada;
    case 'JST-9-NO-DST':
      return loc(context).timezoneJapanKorea;
    case 'EST5':
      return loc(context).timezoneEasternTimeUsaAndCanada;
    case 'ICT-7-NO-DST':
      return loc(context).timezoneThailandRussia;
    case 'HKT-8-NO-DST':
      return loc(context).timezoneChinaHongKongAustraliaWestern;
    case 'WST11-NO-DST':
      return loc(context).timezoneMidwayIslandSamoa;
    case 'FJT-12-NO-DST':
      return loc(context).timezoneFiji;
    case 'NZST-12':
      return loc(context).timezoneNewZealand;
    case 'SBT-11-NO-DST':
      return loc(context).timezoneSolomonIslands;
    case 'CET-1':
      return loc(context).timezoneFranceGermanyItaly;
    case 'MAT2-NO-DST':
      return loc(context).timezoneMidAtlantic;
    case 'MHT12-NO-DST':
      return loc(context).timezoneKwajalein;
    case 'AST-3-NO-DST':
      return loc(context).timezoneTurkeyIraqJordanKuwait;
    case 'CET-1-NO-DST':
      return loc(context).timezoneTunisia;
    case 'ART3-NO-DST':
      return loc(context).timezoneGuyana;
    case 'IST-05:30-NO-DST':
      return loc(context).timezoneMumbaiKolkataChennaiNewDelhi;
    case 'VET4-NO-DST':
      return loc(context).timezoneBoliviaVenezuela;
    case 'GMT0':
      return loc(context).timezoneEngland;
    case 'SAST-2-NO-DST':
      return loc(context).timezoneSouthAfrica;
    case 'AKST9':
      return loc(context).timezoneAlaska;
    case 'MST7':
      return loc(context).timezoneMountainTimeUsaAndCanada;
    case 'CLT4':
      return loc(context).timezoneChileTimeChileAntarctica;
    case 'AST4':
      return loc(context)
          .timezoneAtlanticTimeCanadaGreenlandAtlanticIslands;
    case 'NST03:30':
      return loc(context).timezoneNewfoundland;
    case 'EET-2':
      return loc(context).timezoneGreeceUkraineRomania;
    case 'GST-10-NO-DST':
      return loc(context).timezoneGuamRussia;
    case 'CST6-NO-DST':
      return loc(context).timezoneMexico;
    case 'SGT-8':
    case 'SGT-8-NO-DST':
      return loc(context).timezoneSingaporeTaiwanRussia;
    default:
      return '';
  }
}

String getTimezoneGMT(String description) {
  return RegExp(r'\(([^)]+)\)').matchAsPrefix(description)?.group(1) ?? '';
}
