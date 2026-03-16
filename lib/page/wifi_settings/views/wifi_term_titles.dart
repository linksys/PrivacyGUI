import 'package:flutter/widgets.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';

String getWifiTypeTitle(BuildContext context, WifiType type) {
  switch (type) {
    case WifiType.main:
      return 'MAIN';
    case WifiType.guest:
      return 'GUEST';
    default:
      return 'MAIN';
  }
}

String getWifiRadioBandTitle(BuildContext context, WifiRadioBand value) {
  switch (value) {
    case WifiRadioBand.radio_24:
      return '2.4 GHz band';
    case WifiRadioBand.radio_5_1:
      return '5 GHz band';
    case WifiRadioBand.radio_5_2:
      return '5 GHz band';
    case WifiRadioBand.radio_6:
      return '6 GHz band';
    default:
      return '2.4 GHz band';
  }
}

String getWifiSecurityTypeTitle(BuildContext context, WifiSecurityType type) {
  switch (type) {
    case WifiSecurityType.open:
      return 'Open';
    case WifiSecurityType.wep:
      return 'WEP';
    case WifiSecurityType.wpaPersonal:
      return 'WPA Personal';
    case WifiSecurityType.wpaEnterprise:
      return 'WPA Enterprise';
    case WifiSecurityType.wpa2Personal:
      return 'WPA2 Personal';
    case WifiSecurityType.wpa2Enterprise:
      return 'WPA2 Enterprise';
    case WifiSecurityType.wpa1Or2MixedPersonal:
      return 'WPA/WPA2 Mixed Personal';
    case WifiSecurityType.wpa1Or2MixedEnterprise:
      return 'WPA/WPA2 Mixed Enterprise';
    case WifiSecurityType.wpa2Or3MixedPersonal:
      return 'WPA2/WPA3 Mixed Personal';
    case WifiSecurityType.wpa3Personal:
      return 'WPA3 Personal';
    case WifiSecurityType.wpa3Enterprise:
      return 'WPA3 Enterprise';
    case WifiSecurityType.enhancedOpenNone:
      return 'Open and Enhanced Open';
    case WifiSecurityType.enhancedOpenOnly:
      return 'Enhanced Open Only';
    default:
      return 'Open';
  }
}

String getWifiWirelessModeTitle(
  BuildContext context,
  WifiWirelessMode mode,
  WifiWirelessMode? defaultMixedMode,
) {
  if (mode == defaultMixedMode) {
    return 'Mixed';
  }
  switch (mode) {
    case WifiWirelessMode.a:
      return '802.11a Only';
    case WifiWirelessMode.b:
      return '802.11b Only';
    case WifiWirelessMode.g:
      return '802.11g Only';
    case WifiWirelessMode.n:
      return '802.11n Only';
    case WifiWirelessMode.ac:
      return '802.11ac Only';
    case WifiWirelessMode.ax:
      return '802.11ax Only';
    case WifiWirelessMode.an:
      return '802.11a/n Only';
    case WifiWirelessMode.bg:
      return '802.11b/g Only';
    case WifiWirelessMode.bn:
      return '802.11b/n Only';
    case WifiWirelessMode.gn:
      return '802.11g/n Only';
    case WifiWirelessMode.anac:
      return '802.11a/n/ac Only';
    case WifiWirelessMode.anacax:
      return '802.11a/n/ac/ax Only';
    case WifiWirelessMode.anacaxbe:
      return '802.11a/n/ac/ax/be Only';
    case WifiWirelessMode.bgn:
      return '802.11b/g/n Only';
    case WifiWirelessMode.bgnac:
      return '802.11b/g/n/ac Only';
    case WifiWirelessMode.bgnax:
      return '802.11b/g/n/ax Only';
    case WifiWirelessMode.axbe:
      return '802.11ax/be Only';
    case WifiWirelessMode.mixed:
      return 'Mixed';
    default:
      return 'Mixed';
  }
}

String getWifiChannelWidthTitle(BuildContext context, WifiChannelWidth value) {
  switch (value) {
    case WifiChannelWidth.auto:
      return 'Auto';
    case WifiChannelWidth.wide20:
      return '20 MHz Only';
    case WifiChannelWidth.wide40:
      return 'Up to 40 MHz';
    case WifiChannelWidth.wide80:
      return 'Up to 80 MHz';
    case WifiChannelWidth.wide160c:
      return 'Contiguous 160 MHz';
    case WifiChannelWidth.wide160nc:
      return 'Non-contiguous 160 MHz';
    default:
      return 'Auto';
  }
}

String getWifiChannelTitle(
  BuildContext context,
  int channel,
  WifiRadioBand radio,
) {
  switch (channel) {
    case 0:
      return 'Auto';
    case 1:
      if (radio == WifiRadioBand.radio_24) {
        return '1 - 2.412 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '1 - 5.955 GHz';
      } else {
        return '';
      }
    case 2:
      if (radio == WifiRadioBand.radio_24) {
        return '2 - 2.417 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '2 - 5.935 GHz';
      } else {
        return '';
      }
    case 3:
      if (radio == WifiRadioBand.radio_24) {
        return '3 - 2.422 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '3 - 5.965 GHz';
      } else {
        return '';
      }
    case 4:
      return '4 - 2.427 GHz';
    case 5:
      if (radio == WifiRadioBand.radio_24) {
        return '5 - 2.432 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '5 - 5.975 GHz';
      } else {
        return '';
      }
    case 6:
      return '6 - 2.437 GHz';
    case 7:
      if (radio == WifiRadioBand.radio_24) {
        return '7 - 2.442 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '7 - 5.985 GHz';
      } else {
        return '';
      }
    case 8:
      return '8 - 2.447 GHz';
    case 9:
      if (radio == WifiRadioBand.radio_24) {
        return '9 - 2.452 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '9 - 5.995 GHz';
      } else {
        return '';
      }
    case 10:
      return '10 - 2.457 GHz';
    case 11:
      if (radio == WifiRadioBand.radio_24) {
        return '11 - 2.462 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '11 - 6.005 GHz';
      } else {
        return '';
      }
    case 12:
      return '12 - 2.467 GHz';
    case 13:
      if (radio == WifiRadioBand.radio_24) {
        return '13 - 2.472 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '13 - 6.015 GHz';
      } else {
        return '';
      }
    case 14:
      return '14 - 2.484 GHz';
    case 15:
      return '15 - 6.025 GHz';
    case 17:
      return '17 - 6.035 GHz';
    case 19:
      return '19 - 6.045 GHz';
    case 21:
      return '21 - 6.055 GHz';
    case 23:
      return '23 - 6.065 GHz';
    case 25:
      return '25 - 6.075 GHz';
    case 27:
      return '27 - 6.085 GHz';
    case 29:
      return '29 - 6.095 GHz';
    case 33:
      return '33 - 6.115 GHz';
    case 35:
      return '35 - 6.125 GHz';
    case 36:
      return '36 - 5.180 GHz';
    case 37:
      return '37 - 6.135 GHz';
    case 39:
      return '39 - 6.145 GHz';
    case 40:
      return '40 - 5.200 GHz';
    case 41:
      return '41 - 6.155 GHz';
    case 42:
      return '42 - 5.210 GHz';
    case 43:
      return '43 - 6.165 GHz';
    case 44:
      return '44 - 5.220 GHz';
    case 45:
      return '45 - 6.175 GHz';
    case 46:
      return '46 - 5.230 GHz';
    case 47:
      return '47 - 6.185 GHz';
    case 48:
      return '48 - 5.240 GHz';
    case 49:
      return '49 - 6.195 GHz';
    case 50:
      return '50 - 5.250 GHz';
    case 51:
      return '51 - 6.205 GHz';
    case 52:
      return '52 - 5.260 GHz';
    case 53:
      return '53 - 6.215 GHz';
    case 54:
      return '54 - 5.270 GHz';
    case 55:
      return '55 - 6.225 GHz';
    case 56:
      return '56 - 5.280 GHz';
    case 57:
      return '57 - 6.235 GHz';
    case 58:
      return '58 - 5.290 GHz';
    case 59:
      return '59 - 6.245 GHz';
    case 60:
      return '60 - 5.300 GHz';
    case 61:
      return '61 - 6.255 GHz';
    case 62:
      return '62 - 5.310 GHz';
    case 64:
      return '64 - 5.320 GHz';
    case 65:
      return '65 - 6.275 GHz';
    case 67:
      return '67 - 6.285 GHz';
    case 69:
      return '69 - 6.295 GHz';
    case 71:
      return '71 - 6.305 GHz';
    case 73:
      return '73 - 6.315 GHz';
    case 77:
      return '77 - 6.335 GHz';
    case 81:
      return '81 - 6.355 GHz';
    case 83:
      return '83 - 6.365 GHz';
    case 85:
      return '85 - 6.375 GHz';
    case 87:
      return '87 - 6.385 GHz';
    case 89:
      return '89 - 6.395 GHz';
    case 91:
      return '91 - 6.405 GHz';
    case 93:
      return '93 - 6.415 GHz';
    case 97:
      return '97 - 6.435 GHz';
    case 99:
      return '99 - 6.445 GHz';
    case 100:
      return '100 - 5.500 GHz';
    case 101:
      return '101 - 6.455 GHz';
    case 102:
      return '102 - 5.510 GHz';
    case 103:
      return '103 - 6.465 GHz';
    case 104:
      return '104 - 5.520 GHz';
    case 105:
      return '105 - 6.475 GHz';
    case 106:
      return '106 - 5.530 GHz';
    case 107:
      return '107 - 6.485 GHz';
    case 108:
      return '108 - 5.540 GHz';
    case 109:
      return '109 - 6.495 GHz';
    case 110:
      return '110 - 5.550 GHz';
    case 111:
      return '111 - 6.505 GHz';
    case 112:
      return '112 - 5.560 GHz';
    case 113:
      return '113 - 6.515 GHz';
    case 114:
      return '114 - 5.570 GHz';
    case 115:
      return '115 - 6.525 GHz';
    case 116:
      return '116 - 5.580 GHz';
    case 117:
      return '117 - 6.535 GHz';
    case 118:
      return '118 - 5.590 GHz';
    case 119:
      return '119 - 6.545 GHz';
    case 120:
      return '120 - 5.600 GHz';
    case 121:
      return '121 - 6.555 GHz';
    case 122:
      return '122 - 5.610 GHz';
    case 123:
      return '123 - 6.565 GHz';
    case 124:
      return '124 - 5.620 GHz';
    case 125:
      return '125 - 6.575 GHz';
    case 126:
      return '126 - 5.630 GHz';
    case 128:
      return '128 - 5.640 GHz';
    case 129:
      return '129 - 6.595 GHz';
    case 131:
      return '131 - 6.605 GHz';
    case 132:
      return '132 - 5.660 GHz';
    case 133:
      return '133 - 6.615 GHz';
    case 134:
      return '134 - 5.670 GHz';
    case 135:
      return '135 - 6.625 GHz';
    case 136:
      return '136 - 5.680 GHz';
    case 137:
      return '137 - 6.635 GHz';
    case 138:
      return '138 - 5.690 GHz';
    case 139:
      return '139 - 6.645 GHz';
    case 140:
      return '140 - 5.700 GHz';
    case 141:
      return '141 - 6.655 GHz';
    case 142:
      return '142 - 5.710 GHz';
    case 143:
      return '143 - 6.665 GHz';
    case 144:
      return '144 - 5.720 GHz';
    case 145:
      return '145 - 6.675 GHz';
    case 147:
      return '147 - 6.685 GHz';
    case 149:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '149 - 5.745 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '149 - 6.695 GHz';
      } else {
        return '';
      }
    case 151:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '151 - 5.755 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '151 - 6.705 GHz';
      } else {
        return '';
      }
    case 153:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '153 - 5.765 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '153 - 6.715 GHz';
      } else {
        return '';
      }
    case 155:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '155 - 5.775 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '155 - 6.725 GHz';
      } else {
        return '';
      }
    case 157:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '157 - 5.785 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '157 - 6.735 GHz';
      } else {
        return '';
      }
    case 161:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '161 - 5.805 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '161 - 6.755 GHz';
      } else {
        return '';
      }
    case 163:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '163 - 5.815 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '163 - 6.765 GHz';
      } else {
        return '';
      }
    case 165:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '165 - 5.825 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '165 - 6.775 GHz';
      } else {
        return '';
      }
    case 167:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '167 - 5.835 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '167 - 6.785 GHz';
      } else {
        return '';
      }
    case 169:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '169 - 5.845 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '169 - 6.795 GHz';
      } else {
        return '';
      }
    case 171:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '171 - 5.855 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '171 - 6.805 GHz';
      } else {
        return '';
      }
    case 173:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '173 - 5.865 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '173 - 6.815 GHz';
      } else {
        return '';
      }
    case 175:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '175 - 5.875 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '175 - 6.825 GHz';
      } else {
        return '';
      }
    case 177:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '177 - 5.885 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '177 - 6.835 GHz';
      } else {
        return '';
      }
    case 179:
      return '179 - 6.845 GHz';
    case 180:
      return '180 - 5.900 GHz';
    case 181:
      return '181 - 6.855 GHz';
    case 182:
      return '182 - 5.910 GHz';
    case 183:
      return '183 - 5.865 GHz';
    case 184:
      return '184 - 5.920 GHz';
    case 185:
      return '185 - 6.875 GHz';
    case 187:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '187 - 5.935 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '187 - 6.885 GHz';
      } else {
        return '';
      }
    case 188:
      return '188 - 5.940 GHz';
    case 189:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '189 - 5.945 GHz';
      } else if (radio == WifiRadioBand.radio_6) {
        return '189 - 6.895 GHz';
      } else {
        return '';
      }
    case 192:
      return '192 - 5.960 GHz';
    case 193:
      return '193 - 6.915 GHz';
    case 195:
      return '195 - 6.925 GHz';
    case 196:
      return '196 - 5.980 GHz';
    case 197:
      return '197 - 6.935 GHz';
    case 199:
      return '199 - 6.945 GHz';
    case 201:
      return '201 - 6.955 GHz';
    case 203:
      return '203 - 6.965 GHz';
    case 205:
      return '205 - 6.975 GHz';
    case 207:
      return '207 - 6.985 GHz';
    case 209:
      return '209 - 6.995 GHz';
    case 211:
      return '211 - 7.005 GHz';
    case 213:
      return '213 - 7.015 GHz';
    case 215:
      return '215 - 7.025 GHz';
    case 217:
      return '217 - 7.035 GHz';
    case 219:
      return '219 - 7.045 GHz';
    case 221:
      return '221 - 7.055 GHz';
    case 225:
      return '225 - 7.075 GHz';
    case 227:
      return '227 - 7.085 GHz';
    case 229:
      return '229 - 7.095 GHz';
    case 233:
      return '233 - 7.115 GHz';
    default:
      return 'Auto';
  }
}
