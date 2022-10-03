
const varMqttGroupId = '{group_id}';
const varMqttNetworkId = '{network_id}';

const keyJnapResult = 'result';
const keyJnapOutput = 'output';
const keyJnapError = 'error';

const jnapResultOk = 'OK';

const keyMqttHeader = 'header';
const keyMqttBody = 'body';
const keyMqttHeaderAction = 'X-JNAP-Action';
const keyMqttHeaderAuthorization = 'X-JNAP-Authorization';
const keyMqttHeaderId = 'X-JNAP-Transaction-Id';

const mqttLocalPublishTopic = 'local/command';
const mqttLocalResponseTopic = '$mqttLocalPublishTopic/response';
const mqttRemotePublishTopic = 'groups/$varMqttGroupId/nets/$varMqttNetworkId';
const mqttRemoteResponseTopic = '$mqttRemotePublishTopic/response';