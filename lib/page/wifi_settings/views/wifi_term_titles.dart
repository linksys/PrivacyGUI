import 'package:flutter/widgets.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';

String getWifiTypeTitle(BuildContext context, WifiType type) {
  switch (type) {
    case WifiType.main:
      return 'MAIN';
    case WifiType.guest:
      return 'GUEST';
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
        return '1 - 2.412 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '1 - 5.955 GHZ';
      } else {
        return '';
      }
    case 2:
      if (radio == WifiRadioBand.radio_24) {
        return '2 - 2.417 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '2 - 5.935 GHZ';
      } else {
        return '';
      }
    case 3:
      if (radio == WifiRadioBand.radio_24) {
        return '3 - 2.422 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '3 - 5.965 GHZ';
      } else {
        return '';
      }
    case 4:
      return '4 - 2.427 GHZ';
    case 5:
      if (radio == WifiRadioBand.radio_24) {
        return '5 - 2.432 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '5 - 5.975 GHZ';
      } else {
        return '';
      }
    case 6:
      return '6 - 2.437 GHZ';
    case 7:
      if (radio == WifiRadioBand.radio_24) {
        return '7 - 2.442 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '7 - 5.985 GHZ';
      } else {
        return '';
      }
    case 8:
      return '8 - 2.447 GHZ';
    case 9:
      if (radio == WifiRadioBand.radio_24) {
        return '9 - 2.452 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '9 - 5.995 GHZ';
      } else {
        return '';
      }
    case 10:
      return '10 - 2.457 GHZ';
    case 11:
      if (radio == WifiRadioBand.radio_24) {
        return '11 - 2.462 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '11 - 6.005 GHZ';
      } else {
        return '';
      }
    case 12:
      return '12 - 2.467 GHZ';
    case 13:
      if (radio == WifiRadioBand.radio_24) {
        return '13 - 2.472 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '13 - 6.015 GHZ';
      } else {
        return '';
      }
    case 14:
      return '14 - 2.484 GHZ';
    case 15:
      return '15 - 6.025 GHZ';
    case 17:
      return '17 - 6.035 GHZ';
    case 19:
      return '19 - 6.045 GHZ';
    case 21:
      return '21 - 6.055 GHZ';
    case 23:
      return '23 - 6.065 GHZ';
    case 25:
      return '25 - 6.075 GHZ';
    case 27:
      return '27 - 6.085 GHZ';
    case 29:
      return '29 - 6.095 GHZ';
    case 33:
      return '33 - 6.115 GHZ';
    case 35:
      return '35 - 6.125 GHZ';
    case 36:
      return '36 - 5.180 GHZ';
    case 37:
      return '37 - 6.135 GHZ';
    case 39:
      return '39 - 6.145 GHZ';
    case 40:
      return '40 - 5.200 GHZ';
    case 41:
      return '41 - 6.155 GHZ';
    case 42:
      return '42 - 5.210 GHZ';
    case 43:
      return '43 - 6.165 GHZ';
    case 44:
      return '44 - 5.220 GHZ';
    case 45:
      return '45 - 6.175 GHZ';
    case 46:
      return '46 - 5.230 GHZ';
    case 47:
      return '47 - 6.185 GHZ';
    case 48:
      return '48 - 5.240 GHZ';
    case 49:
      return '49 - 6.195 GHZ';
    case 50:
      return '50 - 5.250 GHZ';
    case 51:
      return '51 - 6.205 GHZ';
    case 52:
      return '52 - 5.260 GHZ';
    case 53:
      return '53 - 6.215 GHZ';
    case 54:
      return '54 - 5.270 GHZ';
    case 55:
      return '55 - 6.225 GHZ';
    case 56:
      return '56 - 5.280 GHZ';
    case 57:
      return '57 - 6.235 GHZ';
    case 58:
      return '58 - 5.290 GHZ';
    case 59:
      return '59 - 6.245 GHZ';
    case 60:
      return '60 - 5.300 GHZ';
    case 61:
      return '61 - 6.255 GHZ';
    case 62:
      return '62 - 5.310 GHZ';
    case 64:
      return '64 - 5.320 GHZ';
    case 65:
      return '65 - 6.275 GHZ';
    case 67:
      return '67 - 6.285 GHZ';
    case 69:
      return '69 - 6.295 GHZ';
    case 71:
      return '71 - 6.305 GHZ';
    case 73:
      return '73 - 6.315 GHZ';
    case 77:
      return '77 - 6.335 GHZ';
    case 81:
      return '81 - 6.355 GHZ';
    case 83:
      return '83 - 6.365 GHZ';
    case 85:
      return '85 - 6.375 GHZ';
    case 87:
      return '87 - 6.385 GHZ';
    case 89:
      return '89 - 6.395 GHZ';
    case 91:
      return '91 - 6.405 GHZ';
    case 93:
      return '93 - 6.415 GHZ';
    case 97:
      return '97 - 6.435 GHZ';
    case 99:
      return '99 - 6.445 GHZ';
    case 100:
      return '100 - 5.500 GHZ';
    case 101:
      return '101 - 6.455 GHZ';
    case 102:
      return '102 - 5.510 GHZ';
    case 103:
      return '103 - 6.465 GHZ';
    case 104:
      return '104 - 5.520 GHZ';
    case 105:
      return '105 - 6.475 GHZ';
    case 106:
      return '106 - 5.530 GHZ';
    case 107:
      return '107 - 6.485 GHZ';
    case 108:
      return '108 - 5.540 GHZ';
    case 109:
      return '109 - 6.495 GHZ';
    case 110:
      return '110 - 5.550 GHZ';
    case 111:
      return '111 - 6.505 GHZ';
    case 112:
      return '112 - 5.560 GHZ';
    case 113:
      return '113 - 6.515 GHZ';
    case 114:
      return '114 - 5.570 GHZ';
    case 115:
      return '115 - 6.525 GHZ';
    case 116:
      return '116 - 5.580 GHZ';
    case 117:
      return '117 - 6.535 GHZ';
    case 118:
      return '118 - 5.590 GHZ';
    case 119:
      return '119 - 6.545 GHZ';
    case 120:
      return '120 - 5.600 GHZ';
    case 121:
      return '121 - 6.555 GHZ';
    case 122:
      return '122 - 5.610 GHZ';
    case 123:
      return '123 - 6.565 GHZ';
    case 124:
      return '124 - 5.620 GHZ';
    case 125:
      return '125 - 6.575 GHZ';
    case 126:
      return '126 - 5.630 GHZ';
    case 128:
      return '128 - 5.640 GHZ';
    case 129:
      return '129 - 6.595 GHZ';
    case 131:
      return '131 - 6.605 GHZ';
    case 132:
      return '132 - 5.660 GHZ';
    case 133:
      return '133 - 6.615 GHZ';
    case 134:
      return '134 - 5.670 GHZ';
    case 135:
      return '135 - 6.625 GHZ';
    case 136:
      return '136 - 5.680 GHZ';
    case 137:
      return '137 - 6.635 GHZ';
    case 138:
      return '138 - 5.690 GHZ';
    case 139:
      return '139 - 6.645 GHZ';
    case 140:
      return '140 - 5.700 GHZ';
    case 141:
      return '141 - 6.655 GHZ';
    case 142:
      return '142 - 5.710 GHZ';
    case 143:
      return '143 - 6.665 GHZ';
    case 144:
      return '144 - 5.720 GHZ';
    case 145:
      return '145 - 6.675 GHZ';
    case 147:
      return '147 - 6.685 GHZ';
    case 149:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '149 - 5.745 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '149 - 6.695 GHZ';
      } else {
        return '';
      }
    case 151:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '151 - 5.755 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '151 - 6.705 GHZ';
      } else {
        return '';
      }
    case 153:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '153 - 5.765 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '153 - 6.715 GHZ';
      } else {
        return '';
      }
    case 155:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '155 - 5.775 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '155 - 6.725 GHZ';
      } else {
        return '';
      }
    case 157:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '157 - 5.785 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '157 - 6.735 GHZ';
      } else {
        return '';
      }
    case 161:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '161 - 5.805 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '161 - 6.755 GHZ';
      } else {
        return '';
      }
    case 163:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '163 - 5.815 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '163 - 6.765 GHZ';
      } else {
        return '';
      }
    case 165:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '165 - 5.825 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '165 - 6.775 GHZ';
      } else {
        return '';
      }
    case 167:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '167 - 5.835 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '167 - 6.785 GHZ';
      } else {
        return '';
      }
    case 169:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '169 - 5.845 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '169 - 6.795 GHZ';
      } else {
        return '';
      }
    case 171:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '171 - 5.855 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '171 - 6.805 GHZ';
      } else {
        return '';
      }
    case 173:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '173 - 5.865 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '173 - 6.815 GHZ';
      } else {
        return '';
      }
    case 175:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '175 - 5.875 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '175 - 6.825 GHZ';
      } else {
        return '';
      }
    case 177:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '177 - 5.885 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '177 - 6.835 GHZ';
      } else {
        return '';
      }
    case 179:
      return '179 - 6.845 GHZ';
    case 180:
      return '180 - 5.900 GHZ';
    case 181:
      return '181 - 6.855 GHZ';
    case 182:
      return '182 - 5.910 GHZ';
    case 183:
      return '183 - 5.865 GHZ';
    case 184:
      return '184 - 5.920 GHZ';
    case 185:
      return '185 - 6.875 GHZ';
    case 187:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '187 - 5.935 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '187 - 6.885 GHZ';
      } else {
        return '';
      }
    case 188:
      return '188 - 5.940 GHZ';
    case 189:
      if (radio == WifiRadioBand.radio_5_1 ||
          radio == WifiRadioBand.radio_5_2) {
        return '189 - 5.945 GHZ';
      } else if (radio == WifiRadioBand.radio_6) {
        return '189 - 6.895 GHZ';
      } else {
        return '';
      }
    case 192:
      return '192 - 5.960 GHZ';
    case 193:
      return '193 - 6.915 GHZ';
    case 195:
      return '195 - 6.925 GHZ';
    case 196:
      return '196 - 5.980 GHZ';
    case 197:
      return '197 - 6.935 GHZ';
    case 199:
      return '199 - 6.945 GHZ';
    case 201:
      return '201 - 6.955 GHZ';
    case 203:
      return '203 - 6.965 GHZ';
    case 205:
      return '205 - 6.975 GHZ';
    case 207:
      return '207 - 6.985 GHZ';
    case 209:
      return '209 - 6.995 GHZ';
    case 211:
      return '211 - 7.005 GHZ';
    case 213:
      return '213 - 7.015 GHZ';
    case 215:
      return '215 - 7.025 GHZ';
    case 217:
      return '217 - 7.035 GHZ';
    case 219:
      return '219 - 7.045 GHZ';
    case 221:
      return '221 - 7.055 GHZ';
    case 225:
      return '225 - 7.075 GHZ';
    case 227:
      return '227 - 7.085 GHZ';
    case 229:
      return '229 - 7.095 GHZ';
    case 233:
      return '233 - 7.115 GHZ';
    default:
      return 'Auto';
  }
}
