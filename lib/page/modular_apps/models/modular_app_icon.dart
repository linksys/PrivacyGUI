import 'package:flutter/material.dart';

/// Enum representing the available Material Icons for modular apps.
/// These icons are used across the modular apps for consistent UI/UX.
enum ModularAppIcon {
  accountTree('account_tree'),
  note('note'),
  album('album'),
  supportAgent('support_agent'),
  appRegistration('app_registration'),
  star('star'),
  home('home'),
  settings('settings'),
  notifications('notifications'),
  dashboard('dashboard'),
  person('person'),
  group('group'),
  email('email'),
  phone('phone'),
  chat('chat'),
  videoCall('video_call'),
  camera('camera'),
  image('image'),
  musicNote('music_note'),
  movie('movie'),
  shoppingCart('shopping_cart'),
  localOffer('local_offer'),
  favorite('favorite'),
  bookmark('bookmark'),
  search('search'),
  refresh('refresh'),
  add('add'),
  edit('edit'),
  delete('delete'),
  info('info'),
  warning('warning'),
  error('error'),
  checkCircle('check_circle'),
  cancel('cancel'),
  arrowBack('arrow_back'),
  arrowForward('arrow_forward'),
  menu('menu'),
  moreVert('more_vert'),
  share('share'),
  download('download'),
  upload('upload'),
  lock('lock'),
  visibility('visibility'),
  visibilityOff('visibility_off'),
  help('help'),
  code('code'),
  build('build'),
  school('school'),
  work('work'),
  public('public'),
  language('language'),
  darkMode('dark_mode'),
  lightMode('light_mode'),
  wifi('wifi'),
  bluetooth('bluetooth'),
  locationOn('location_on'),
  map('map'),
  qrCode('qr_code'),
  security('security'),
  verifiedUser('verified_user'),
  history('history'),
  schedule('schedule'),
  today('today'),
  event('event'),
  calendarToday('calendar_today'),
  attachMoney('attach_money'),
  creditCard('credit_card'),
  shoppingBag('shopping_bag'),
  localShipping('local_shipping'),
  assessment('assessment'),
  trendingUp('trending_up'),
  pieChart('pie_chart'),
  barChart('bar_chart'),
  listAlt('list_alt'),
  viewList('view_list'),
  gridView('grid_view'),
  tableChart('table_chart'),
  sort('sort'),
  filterList('filter_list'),
  tune('tune'),
  contentCopy('content_copy'),
  save('save'),
  print('print'),
  cloud('cloud'),
  cloudUpload('cloud_upload'),
  cloudDownload('cloud_download'),
  cloudSync('cloud_sync'),
  batteryFull('battery_full'),
  batteryCharging('battery_charging'),
  storage('storage'),
  sdCard('sd_card'),
  usb('usb'),
  power('power'),
  powerOff('power_off'),
  powerSettingsNew('power_settings_new');

  final String value;

  const ModularAppIcon(this.value);

  /// Converts a string value to the corresponding ModularAppIcon enum.
  /// Returns null if no match is found.
  static ModularAppIcon fromString(String value) {
    try {
      return ModularAppIcon.values.firstWhere(
        (icon) => icon.value == value,
      );
    } catch (e) {
      return ModularAppIcon.accountTree;
    }
  }

  /// Returns the corresponding IconData from the Flutter Icons class.
  /// Throws an error if no matching icon is found.
  IconData get iconData {
    switch (this) {
      case ModularAppIcon.accountTree:
        return Icons.account_tree;
      case ModularAppIcon.note:
        return Icons.note;
      case ModularAppIcon.album:
        return Icons.album;
      case ModularAppIcon.supportAgent:
        return Icons.support_agent;
      case ModularAppIcon.appRegistration:
        return Icons.app_registration;
      case ModularAppIcon.star:
        return Icons.star;
      case ModularAppIcon.home:
        return Icons.home;
      case ModularAppIcon.settings:
        return Icons.settings;
      case ModularAppIcon.notifications:
        return Icons.notifications;
      case ModularAppIcon.dashboard:
        return Icons.dashboard;
      case ModularAppIcon.person:
        return Icons.person;
      case ModularAppIcon.group:
        return Icons.group;
      case ModularAppIcon.email:
        return Icons.email;
      case ModularAppIcon.phone:
        return Icons.phone;
      case ModularAppIcon.chat:
        return Icons.chat;
      case ModularAppIcon.videoCall:
        return Icons.video_call;
      case ModularAppIcon.camera:
        return Icons.camera_alt;
      case ModularAppIcon.image:
        return Icons.image;
      case ModularAppIcon.musicNote:
        return Icons.music_note;
      case ModularAppIcon.movie:
        return Icons.movie;
      case ModularAppIcon.shoppingCart:
        return Icons.shopping_cart;
      case ModularAppIcon.localOffer:
        return Icons.local_offer;
      case ModularAppIcon.favorite:
        return Icons.favorite;
      case ModularAppIcon.bookmark:
        return Icons.bookmark;
      case ModularAppIcon.search:
        return Icons.search;
      case ModularAppIcon.refresh:
        return Icons.refresh;
      case ModularAppIcon.add:
        return Icons.add;
      case ModularAppIcon.edit:
        return Icons.edit;
      case ModularAppIcon.delete:
        return Icons.delete;
      case ModularAppIcon.info:
        return Icons.info;
      case ModularAppIcon.warning:
        return Icons.warning;
      case ModularAppIcon.error:
        return Icons.error;
      case ModularAppIcon.checkCircle:
        return Icons.check_circle;
      case ModularAppIcon.cancel:
        return Icons.cancel;
      case ModularAppIcon.arrowBack:
        return Icons.arrow_back;
      case ModularAppIcon.arrowForward:
        return Icons.arrow_forward;
      case ModularAppIcon.menu:
        return Icons.menu;
      case ModularAppIcon.moreVert:
        return Icons.more_vert;
      case ModularAppIcon.share:
        return Icons.share;
      case ModularAppIcon.download:
        return Icons.download;
      case ModularAppIcon.upload:
        return Icons.upload;
      case ModularAppIcon.lock:
        return Icons.lock;
      case ModularAppIcon.visibility:
        return Icons.visibility;
      case ModularAppIcon.visibilityOff:
        return Icons.visibility_off;
      case ModularAppIcon.help:
        return Icons.help;
      case ModularAppIcon.code:
        return Icons.code;
      case ModularAppIcon.build:
        return Icons.build;
      case ModularAppIcon.school:
        return Icons.school;
      case ModularAppIcon.work:
        return Icons.work;
      case ModularAppIcon.public:
        return Icons.public;
      case ModularAppIcon.language:
        return Icons.language;
      case ModularAppIcon.darkMode:
        return Icons.dark_mode;
      case ModularAppIcon.lightMode:
        return Icons.light_mode;
      case ModularAppIcon.wifi:
        return Icons.wifi;
      case ModularAppIcon.bluetooth:
        return Icons.bluetooth;
      case ModularAppIcon.locationOn:
        return Icons.location_on;
      case ModularAppIcon.map:
        return Icons.map;
      case ModularAppIcon.qrCode:
        return Icons.qr_code;
      case ModularAppIcon.security:
        return Icons.security;
      case ModularAppIcon.verifiedUser:
        return Icons.verified_user;
      case ModularAppIcon.history:
        return Icons.history;
      case ModularAppIcon.schedule:
        return Icons.schedule;
      case ModularAppIcon.today:
        return Icons.today;
      case ModularAppIcon.event:
        return Icons.event;
      case ModularAppIcon.calendarToday:
        return Icons.calendar_today;
      case ModularAppIcon.attachMoney:
        return Icons.attach_money;
      case ModularAppIcon.creditCard:
        return Icons.credit_card;
      case ModularAppIcon.shoppingBag:
        return Icons.shopping_bag;
      case ModularAppIcon.localShipping:
        return Icons.local_shipping;
      case ModularAppIcon.assessment:
        return Icons.assessment;
      case ModularAppIcon.trendingUp:
        return Icons.trending_up;
      case ModularAppIcon.pieChart:
        return Icons.pie_chart;
      case ModularAppIcon.barChart:
        return Icons.bar_chart;
      case ModularAppIcon.listAlt:
        return Icons.list_alt;
      case ModularAppIcon.viewList:
        return Icons.view_list;
      case ModularAppIcon.gridView:
        return Icons.grid_view;
      case ModularAppIcon.tableChart:
        return Icons.table_chart;
      case ModularAppIcon.sort:
        return Icons.sort;
      case ModularAppIcon.filterList:
        return Icons.filter_list;
      case ModularAppIcon.tune:
        return Icons.tune;
      case ModularAppIcon.contentCopy:
        return Icons.content_copy;
      case ModularAppIcon.save:
        return Icons.save;
      case ModularAppIcon.print:
        return Icons.print;
      case ModularAppIcon.cloud:
        return Icons.cloud;
      case ModularAppIcon.cloudUpload:
        return Icons.cloud_upload;
      case ModularAppIcon.cloudDownload:
        return Icons.cloud_download;
      case ModularAppIcon.cloudSync:
        return Icons.cloud_sync;
      case ModularAppIcon.batteryFull:
        return Icons.battery_full;
      case ModularAppIcon.batteryCharging:
        return Icons.battery_charging_full;
      case ModularAppIcon.storage:
        return Icons.storage;
      case ModularAppIcon.sdCard:
        return Icons.sd_card;
      case ModularAppIcon.usb:
        return Icons.usb;
      case ModularAppIcon.power:
        return Icons.power;
      case ModularAppIcon.powerOff:
        return Icons.power_off;
      case ModularAppIcon.powerSettingsNew:
        return Icons.power_settings_new;
    }
  }

  /// Returns an Icon widget with the specified size and color.
  /// If color is not provided, it will use the default icon color.
  Icon toIcon({double? size, Color? color}) {
    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }

  @override
  String toString() => value;
}
