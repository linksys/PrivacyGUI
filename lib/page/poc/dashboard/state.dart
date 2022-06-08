import 'package:equatable/equatable.dart';

class DashboardState extends Equatable{
  const DashboardState._({this.ssid = ""});

  final String ssid;

  const DashboardState.initial(): this._(ssid: '');
  const DashboardState.ssidFetched(String ssid): this._(ssid: ssid);
  const DashboardState.ssidFetchFailed(): this._(ssid: '');

  @override
  List<Object?> get props => [ssid];
}
