import 'package:flutter/material.dart';
import 'package:linksys_moab/bloc/security/state.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/components/chart/BarChartSample1.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/model/security_path.dart';
import 'package:linksys_moab/route/_route.dart';


//TODO: Remove this temp model when the real data is involved.
class CyberThreatModel {
  String content;
  String deviceName;
  String time;
  String date;

  CyberThreatModel(this.content, this.deviceName, this.time, this.date);
}

class SecurityCyberThreatView extends ArgumentsStatefulView {
  const SecurityCyberThreatView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _SecurityCyberThreatViewState createState() =>
      _SecurityCyberThreatViewState();
}

class _SecurityCyberThreatViewState extends State<SecurityCyberThreatView> {
  late CyberthreatType currentType;
  final List<CyberThreatModel> dummyData = [
    CyberThreatModel('MSIL/Samas.1AE3!tr.ransom', 'Device name',
        '6.11 pm', 'Sept 15'),
    CyberThreatModel('PDF/Agent.A6A0!tr', 'Device name', '1.23 pm', 'Sept 12'),
    CyberThreatModel('Java/Spring4shell.A!tr', 'Device name',
        '1.25 pm', 'Sept 12'),
    CyberThreatModel('MSIL/Samas.1AE3!tr.ransom', 'Device name',
        '6.11 pm', 'Sept 15'),
    CyberThreatModel('PDF/Agent.A6A0!tr', 'Device name', '1.23 pm', 'Sept 12'),
    CyberThreatModel('Java/Spring4shell.A!tr', 'Device name',
        '1.25 pm', 'Sept 12'),
    CyberThreatModel('MSIL/Samas.1AE3!tr.ransom', 'Device name',
        '6.11 pm', 'Sept 15'),
    CyberThreatModel('PDF/Agent.A6A0!tr', 'Device name', '1.23 pm', 'Sept 12'),
    CyberThreatModel('Java/Spring4shell.A!tr', 'Device name',
        '1.25 pm', 'Sept 12'),
    CyberThreatModel('MSIL/Samas.1AE3!tr.ransom', 'Device name',
        '6.11 pm', 'Sept 15'),
    CyberThreatModel('PDF/Agent.A6A0!tr', 'Device name', '1.23 pm', 'Sept 12'),
    CyberThreatModel('Java/Spring4shell.A!tr', 'Device name',
        '1.25 pm', 'Sept 12'),
  ];

  @override
  initState() {
    super.initState();
    if (widget.args.containsKey('type')) {
      currentType = widget.args['type'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: currentType.displayTitle,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getPageSubtitle(),
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Image.asset(
                    'assets/images/icon_info.png',
                    height: 26,
                    width: 26,
                  ),
                  onPressed: () {
                    NavigationCubit.of(context).push(
                      VulnerabilityIntroductionPath()
                    );
                  },
                )
              ],
            ),
            BarChartSample1(),
            Expanded(
              child: ListView.builder(
                  itemCount: dummyData.length,
                  itemBuilder: (context, index) =>
                      InkWell(
                        child: Container(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getItemTitle(),
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headline4
                                        ?.copyWith(
                                      color: Theme
                                          .of(context)
                                          .colorScheme
                                          .surface,
                                    ),
                                  ),
                                  Text(
                                    dummyData[index].content,
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headline3
                                        ?.copyWith(
                                      color: Theme
                                          .of(context)
                                          .primaryColor,
                                    ),
                                  ),
                                  Text(
                                    dummyData[index].deviceName,
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headline4
                                        ?.copyWith(
                                      color: Theme
                                          .of(context)
                                          .colorScheme
                                          .onTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    dummyData[index].time,
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headline3
                                        ?.copyWith(
                                      color: Theme
                                          .of(context)
                                          .colorScheme
                                          .surface,
                                    ),
                                  ),
                                  Text(
                                    dummyData[index].date,
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headline4
                                        ?.copyWith(
                                      color: Theme
                                          .of(context)
                                          .colorScheme
                                          .surface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onTap: () {
                          //TODO: Go to next page
                        },
                      )
              ),
            ),
            Image.asset('assets/images/secured_by_fortinet.png'),
          ],
        ),
      ),
    );
  }

  String _getPageSubtitle() {
    switch(currentType) {
      case CyberthreatType.virus:
        return 'Virus blocked ${dummyData.length}';
      case CyberthreatType.malware:
        return 'Ransomware & Malware blocked ${dummyData.length}';
      case CyberthreatType.botnet:
        return 'Botnet blocked ${dummyData.length}';
      case CyberthreatType.website:
        return 'Malicious websites ${dummyData.length}';
    }
  }

  String _getItemTitle() {
    switch(currentType) {
      case CyberthreatType.virus:
        return 'VIRUS';
      case CyberthreatType.malware:
        return 'MALWARE';
      case CyberthreatType.botnet:
        return 'BOTNET';
      case CyberthreatType.website:
        return 'WEBSITE';
    }
  }
}
