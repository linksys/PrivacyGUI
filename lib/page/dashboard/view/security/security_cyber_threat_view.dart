import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/dashboard/view/security/BarChartSample1.dart';

enum CyberThreatType {
  virus,
  malware,
  botnet,
  malicious,
}

//TODO: Remove this temp model when the real data is involved.
class CyberThreatModel {
  String type;
  String content;
  String deviceName;
  String time;
  String date;

  CyberThreatModel(this.type, this.content, this.deviceName, this.time,
      this.date);
}

class SecurityCyberThreatView extends StatefulWidget {
  const SecurityCyberThreatView({Key? key}) : super(key: key);

  @override
  _SecurityCyberThreatViewState createState() =>
      _SecurityCyberThreatViewState();
}

class _SecurityCyberThreatViewState extends State<SecurityCyberThreatView> {
  final List<CyberThreatModel> dummyData = [
    CyberThreatModel('MALWARE', 'MSIL/Samas.1AE3!tr.ransom', 'Device name',
        '6.11 pm', 'Sept 15'),
    CyberThreatModel(
        'MALWARE', 'PDF/Agent.A6A0!tr', 'Device name', '1.23 pm', 'Sept 12'),
    CyberThreatModel('RANSOMWARE', 'Java/Spring4shell.A!tr', 'Device name',
        '1.25 pm', 'Sept 12'),
    CyberThreatModel('MALWARE', 'MSIL/Samas.1AE3!tr.ransom', 'Device name',
        '6.11 pm', 'Sept 15'),
    CyberThreatModel(
        'MALWARE', 'PDF/Agent.A6A0!tr', 'Device name', '1.23 pm', 'Sept 12'),
    CyberThreatModel('RANSOMWARE', 'Java/Spring4shell.A!tr', 'Device name',
        '1.25 pm', 'Sept 12'),
    CyberThreatModel('MALWARE', 'MSIL/Samas.1AE3!tr.ransom', 'Device name',
        '6.11 pm', 'Sept 15'),
    CyberThreatModel(
        'MALWARE', 'PDF/Agent.A6A0!tr', 'Device name', '1.23 pm', 'Sept 12'),
    CyberThreatModel('RANSOMWARE', 'Java/Spring4shell.A!tr', 'Device name',
        '1.25 pm', 'Sept 12'),
    CyberThreatModel('MALWARE', 'MSIL/Samas.1AE3!tr.ransom', 'Device name',
        '6.11 pm', 'Sept 15'),
    CyberThreatModel(
        'MALWARE', 'PDF/Agent.A6A0!tr', 'Device name', '1.23 pm', 'Sept 12'),
    CyberThreatModel('RANSOMWARE', 'Java/Spring4shell.A!tr', 'Device name',
        '1.25 pm', 'Sept 12'),
  ];

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Ransomware & Malware',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                    dummyData[index].type,
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
}
