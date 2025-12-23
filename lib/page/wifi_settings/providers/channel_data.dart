// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

const List<Map<String, dynamic>> channelData = [
  {
    'band': '2.4GHz',
    'channel': 1,
    'frequency': '2.412',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 2,
    'frequency': '2.417',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 3,
    'frequency': '2.422',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 4,
    'frequency': '2.427',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 5,
    'frequency': '2.432',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 6,
    'frequency': '2.437',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 7,
    'frequency': '2.442',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 8,
    'frequency': '2.447',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 9,
    'frequency': '2.452',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 10,
    'frequency': '2.457',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 11,
    'frequency': '2.462',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 12,
    'frequency': '2.467',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 13,
    'frequency': '2.472',
    'dfs': false,
    'unii': []
  },
  {
    'band': '2.4GHz',
    'channel': 14,
    'frequency': '2.484',
    'dfs': false,
    'unii': []
  },
  {
    'band': '5GHz',
    'channel': 32,
    'frequency': '5.160',
    'dfs': false,
    'unii': [1]
  },
  {
    'band': '5GHz',
    'channel': 34,
    'frequency': '5.170',
    'dfs': false,
    'unii': [1]
  },
  {
    'band': '5GHz',
    'channel': 36,
    'frequency': '5.180',
    'dfs': false,
    'unii': [1]
  },
  {
    'band': '5GHz',
    'channel': 38,
    'frequency': '5.190',
    'dfs': false,
    'unii': [1]
  },
  {
    'band': '5GHz',
    'channel': 40,
    'frequency': '5.200',
    'dfs': false,
    'unii': [1]
  },
  {
    'band': '5GHz',
    'channel': 42,
    'frequency': '5.210',
    'dfs': false,
    'unii': [1]
  },
  {
    'band': '5GHz',
    'channel': 44,
    'frequency': '5.220',
    'dfs': false,
    'unii': [1]
  },
  {
    'band': '5GHz',
    'channel': 46,
    'frequency': '5.230',
    'dfs': false,
    'unii': [1]
  },
  {
    'band': '5GHz',
    'channel': 48,
    'frequency': '5.240',
    'dfs': false,
    'unii': [1]
  },
  {
    'band': '5GHz',
    'channel': 50,
    'frequency': '5.250',
    'dfs': true,
    'unii': [1, 2]
  },
  {
    'band': '5GHz',
    'channel': 52,
    'frequency': '5.260',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 54,
    'frequency': '5.270',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 56,
    'frequency': '5.280',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 58,
    'frequency': '5.290',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 60,
    'frequency': '5.300',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 62,
    'frequency': '5.310',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 64,
    'frequency': '5.320',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 100,
    'frequency': '5.500',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 102,
    'frequency': '5.510',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 104,
    'frequency': '5.520',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 106,
    'frequency': '5.530',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 108,
    'frequency': '5.540',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 110,
    'frequency': '5.550',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 112,
    'frequency': '5.560',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 114,
    'frequency': '5.570',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 116,
    'frequency': '5.580',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 118,
    'frequency': '5.590',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 120,
    'frequency': '5.600',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 122,
    'frequency': '5.610',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 124,
    'frequency': '5.620',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 126,
    'frequency': '5.630',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 128,
    'frequency': '5.640',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 132,
    'frequency': '5.660',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 134,
    'frequency': '5.670',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 136,
    'frequency': '5.680',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 138,
    'frequency': '5.690',
    'dfs': true,
    'unii': [2, 3]
  },
  {
    'band': '5GHz',
    'channel': 140,
    'frequency': '5.700',
    'dfs': true,
    'unii': [2]
  },
  {
    'band': '5GHz',
    'channel': 142,
    'frequency': '5.710',
    'dfs': true,
    'unii': [2, 3]
  },
  {
    'band': '5GHz',
    'channel': 144,
    'frequency': '5.720',
    'dfs': true,
    'unii': [2, 3]
  },
  {
    'band': '5GHz',
    'channel': 149,
    'frequency': '5.745',
    'dfs': false,
    'unii': [3]
  },
  {
    'band': '5GHz',
    'channel': 151,
    'frequency': '5.755',
    'dfs': false,
    'unii': [3]
  },
  {
    'band': '5GHz',
    'channel': 153,
    'frequency': '5.765',
    'dfs': false,
    'unii': [3]
  },
  {
    'band': '5GHz',
    'channel': 155,
    'frequency': '5.775',
    'dfs': false,
    'unii': [3]
  },
  {
    'band': '5GHz',
    'channel': 157,
    'frequency': '5.785',
    'dfs': false,
    'unii': [3]
  },
  {
    'band': '5GHz',
    'channel': 161,
    'frequency': '5.805',
    'dfs': false,
    'unii': [3]
  },
  {
    'band': '5GHz',
    'channel': 163,
    'frequency': '5.815',
    'dfs': false,
    'unii': [3, 4]
  },
  {
    'band': '5GHz',
    'channel': 165,
    'frequency': '5.825',
    'dfs': false,
    'unii': [3]
  },
  {
    'band': '5GHz',
    'channel': 167,
    'frequency': '5.835',
    'dfs': false,
    'unii': [3, 4]
  },
  {
    'band': '5GHz',
    'channel': 169,
    'frequency': '5.845',
    'dfs': false,
    'unii': [4]
  },
  {
    'band': '5GHz',
    'channel': 171,
    'frequency': '5.855',
    'dfs': false,
    'unii': [3, 4]
  },
  {
    'band': '5GHz',
    'channel': 173,
    'frequency': '5.865',
    'dfs': false,
    'unii': [4]
  },
  {
    'band': '5GHz',
    'channel': 175,
    'frequency': '5.875',
    'dfs': false,
    'unii': [4]
  },
  {
    'band': '5GHz',
    'channel': 177,
    'frequency': '5.885',
    'dfs': false,
    'unii': [4]
  },
  {
    'band': '5GHz',
    'channel': 180,
    'frequency': '5.900',
    'dfs': false,
    'unii': []
  },
  {
    'band': '5GHz',
    'channel': 182,
    'frequency': '5.910',
    'dfs': false,
    'unii': []
  },
  {
    'band': '5GHz',
    'channel': 184,
    'frequency': '5.920',
    'dfs': false,
    'unii': []
  },
  {
    'band': '5GHz',
    'channel': 187,
    'frequency': '5.935',
    'dfs': false,
    'unii': []
  },
  {
    'band': '5GHz',
    'channel': 188,
    'frequency': '5.940',
    'dfs': false,
    'unii': []
  },
  {
    'band': '5GHz',
    'channel': 189,
    'frequency': '5.945',
    'dfs': false,
    'unii': []
  },
  {
    'band': '5GHz',
    'channel': 192,
    'frequency': '5.960',
    'dfs': false,
    'unii': []
  },
  {
    'band': '5GHz',
    'channel': 196,
    'frequency': '5.980',
    'dfs': false,
    'unii': []
  },
  {
    'band': '6GHz',
    'channel': 1,
    'frequency': '5.955',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 2,
    'frequency': '5.935',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 3,
    'frequency': '5.965',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 5,
    'frequency': '5.975',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 7,
    'frequency': '5.985',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 9,
    'frequency': '5.995',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 11,
    'frequency': '6.005',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 13,
    'frequency': '6.015',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 15,
    'frequency': '6.025',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 17,
    'frequency': '6.035',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 19,
    'frequency': '6.045',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 21,
    'frequency': '6.055',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 23,
    'frequency': '6.065',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 25,
    'frequency': '6.075',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 27,
    'frequency': '6.085',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 29,
    'frequency': '6.095',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 33,
    'frequency': '6.115',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 35,
    'frequency': '6.125',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 37,
    'frequency': '6.135',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 39,
    'frequency': '6.145',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 41,
    'frequency': '6.155',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 43,
    'frequency': '6.165',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 45,
    'frequency': '6.175',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 47,
    'frequency': '6.185',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 49,
    'frequency': '6.195',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 51,
    'frequency': '6.205',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 53,
    'frequency': '6.215',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 55,
    'frequency': '6.225',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 57,
    'frequency': '6.235',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 59,
    'frequency': '6.245',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 61,
    'frequency': '6.255',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 65,
    'frequency': '6.275',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 67,
    'frequency': '6.285',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 69,
    'frequency': '6.295',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 71,
    'frequency': '6.305',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 73,
    'frequency': '6.315',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 75,
    'frequency': '6.325',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 77,
    'frequency': '6.335',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 79,
    'frequency': '6.345',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 81,
    'frequency': '6.355',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 83,
    'frequency': '6.365',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 85,
    'frequency': '6.375',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 87,
    'frequency': '6.385',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 89,
    'frequency': '6.395',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 91,
    'frequency': '6.405',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 93,
    'frequency': '6.415',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 97,
    'frequency': '6.435',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 99,
    'frequency': '6.445',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 101,
    'frequency': '6.455',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 103,
    'frequency': '6.465',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 105,
    'frequency': '6.475',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 107,
    'frequency': '6.485',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 109,
    'frequency': '6.495',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 111,
    'frequency': '6.505',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 113,
    'frequency': '6.515',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 115,
    'frequency': '6.525',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 117,
    'frequency': '6.535',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 119,
    'frequency': '6.545',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 121,
    'frequency': '6.555',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 123,
    'frequency': '6.565',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 125,
    'frequency': '6.575',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 129,
    'frequency': '6.595',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 131,
    'frequency': '6.605',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 133,
    'frequency': '6.615',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 135,
    'frequency': '6.625',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 137,
    'frequency': '6.635',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 139,
    'frequency': '6.645',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 141,
    'frequency': '6.655',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 143,
    'frequency': '6.665',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 145,
    'frequency': '6.675',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 147,
    'frequency': '6.685',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 149,
    'frequency': '6.695',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 151,
    'frequency': '6.705',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 153,
    'frequency': '6.715',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 155,
    'frequency': '6.725',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 157,
    'frequency': '6.735',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 161,
    'frequency': '6.755',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 163,
    'frequency': '6.765',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 165,
    'frequency': '6.775',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 167,
    'frequency': '6.785',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 169,
    'frequency': '6.795',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 171,
    'frequency': '6.805',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 173,
    'frequency': '6.815',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 175,
    'frequency': '6.825',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 177,
    'frequency': '6.835',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 179,
    'frequency': '6.845',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 181,
    'frequency': '6.855',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 183,
    'frequency': '6.865',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 185,
    'frequency': '6.875',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 187,
    'frequency': '6.885',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 189,
    'frequency': '6.895',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 193,
    'frequency': '6.915',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 195,
    'frequency': '6.925',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 197,
    'frequency': '6.935',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 199,
    'frequency': '6.945',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 201,
    'frequency': '6.955',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 203,
    'frequency': '6.965',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 205,
    'frequency': '6.975',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 207,
    'frequency': '6.985',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 209,
    'frequency': '6.995',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 211,
    'frequency': '7.005',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 213,
    'frequency': '7.015',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 215,
    'frequency': '7.025',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 217,
    'frequency': '7.035',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 219,
    'frequency': '7.045',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 221,
    'frequency': '7.055',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 225,
    'frequency': '7.075',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 227,
    'frequency': '7.085',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 229,
    'frequency': '7.095',
    'dfs': false,
    'unii': [5]
  },
  {
    'band': '6GHz',
    'channel': 233,
    'frequency': '7.115',
    'dfs': false,
    'unii': [5]
  }
];

class ChannelDataInfo extends Equatable {
  final String band;
  final int channel;
  final String frequency;
  final bool dfs;
  final List<int> unii;
  const ChannelDataInfo({
    required this.band,
    required this.channel,
    required this.frequency,
    required this.dfs,
    required this.unii,
  });

  ChannelDataInfo copyWith({
    String? band,
    int? channel,
    String? frequency,
    bool? dfs,
    List<int>? unii,
  }) {
    return ChannelDataInfo(
      band: band ?? this.band,
      channel: channel ?? this.channel,
      frequency: frequency ?? this.frequency,
      dfs: dfs ?? this.dfs,
      unii: unii ?? this.unii,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'band': band,
      'channel': channel,
      'frequency': frequency,
      'dfs': dfs,
      'unii': unii,
    };
  }

  factory ChannelDataInfo.fromMap(Map<String, dynamic> map) {
    return ChannelDataInfo(
        band: map['band'] as String,
        channel: map['channel'] as int,
        frequency: map['frequency'] as String,
        dfs: map['dfs'] as bool,
        unii: List<int>.from(
          (map['unii']),
        ));
  }

  String toJson() => json.encode(toMap());

  factory ChannelDataInfo.fromJson(String source) =>
      ChannelDataInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      band,
      channel,
      frequency,
      dfs,
      unii,
    ];
  }
}
