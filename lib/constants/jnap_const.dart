
const kJNAPActionBase = 'http://linksys.com';
const kJNAPActionPrefix = '$kJNAPActionBase/jnap';
const kJNAPSession = 'X-JNAP-Session';
const kJNAPAction = 'X-JNAP-Action';
const kJNAPAuthorization = 'X-JNAP-Authorization';
const kJNAPNetworkId = 'X-Linksys-Network-Id';
//
const varMqttGroupId = '{group_id}';
const varMqttNetworkId = '{network_id}';

const keyJnapResult = 'result';
const keyJnapOutput = 'output';
const keyJnapResponses = 'responses';
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

const userDefinedDeviceLocation = 'userDeviceLocation';
const userDefinedDeviceName = 'userDeviceName';