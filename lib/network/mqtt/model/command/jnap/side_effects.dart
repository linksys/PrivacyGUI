import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';

class WiFiInterruptCommand extends JnapCommand {
  WiFiInterruptCommand({
    super.publishTopic = '',
    super.responseTopic = '',
    super.action = 'WiFiInterrupt',
    super.data = const {},
  });
}
