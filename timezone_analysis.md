# 完整時區列表分析

基於用戶提供的 JSON，SoC 支援的完整時區列表（39個）：

## 原始 JSON 時區清單

| # | timeZoneID | utcOffsetMinutes | observesDST | description |
|---|------------|------------------|-------------|-------------|
| 1 | GMT0-NO-DST | 0 | false | "(GMT) Gambia, Liberia, Morocco" |
| 2 | GST-4-NO-DST | 240 | false | "(GMT+04:00) Armenia" |
| 3 | EST5-NO-DST | -300 | false | "(GMT-05:00) Indiana East, Colombia, Panama" |
| 4 | AEST-10 | 600 | true | "(GMT+10:00) Australia" |
| 5 | MST7-NO-DST | -420 | false | "(GMT-07:00) Arizona" |
| 6 | PKT-5-NO-DST | 300 | false | "(GMT+05:00) Pakistan, Russia" |
| 7 | ALMT-6-NO-DST | 360 | false | "(GMT+06:00) Bangladesh, Russia" |
| 8 | NST03:30 | -210 | true | "(GMT-03:30) Newfoundland" |
| 9 | BRT3 | -180 | true | "(GMT-03:00) Brazil East, Greenland" |
| 10 | HST10-NO-DST | -600 | false | "(GMT-10:00) Hawaii" |
| 11 | CST6 | -360 | true | "(GMT-06:00) Central Time (USA & Canada)" |
| 12 | PST8 | -480 | true | "(GMT-08:00) Pacific Time (USA & Canada)" |
| 13 | JST-9-NO-DST | 540 | false | "(GMT+09:00) Japan, Korea" |
| 14 | EST5 | -300 | true | "(GMT-05:00) Eastern Time (USA & Canada)" |
| 15 | ICT-7-NO-DST | 420 | false | "(GMT+07:00) Thailand, Russia" |
| 16 | HKT-8-NO-DST | 480 | false | "(GMT+08:00) China, Hong Kong, Australia Western" |
| 17 | WST11-NO-DST | -660 | false | "(GMT-11:00) Midway Island, Samoa" |
| 18 | SBT-11-NO-DST | 660 | false | "(GMT+11:00) Solomon Islands" |
| 19 | FJT-12-NO-DST | 720 | false | "(GMT+12:00) Fiji" |
| 20 | NZST-12 | 720 | true | "(GMT+12:00) New Zealand" |
| 21 | GST-10-NO-DST | 600 | false | "(GMT+10:00) Guam, Russia" |
| 22 | CET-1-NO-DST | 60 | false | "(GMT+01:00) Tunisia" |
| 23 | MAT2-NO-DST | -120 | false | "(GMT-02:00) Mid-Atlantic" |
| 24 | MHT12-NO-DST | -720 | false | "(GMT-12:00) Kwajalein" |
| 25 | AZOT1 | -60 | true | "(GMT-01:00) Azores" |
| 26 | CET-1 | 60 | true | "(GMT+01:00) France, Germany, Italy" |
| 27 | ART3-NO-DST | -180 | false | "(GMT-03:00) Guyana" |
| 28 | IST-05:30-NO-DST | 330 | false | "(GMT+05:30) Bombay, Kalkutta, Madras, Neu Delhi" |
| 29 | VET4-NO-DST | -240 | false | "(GMT-04:00) Bolivia, Venezuela" |
| 30 | GMT0 | 0 | true | "(GMT) England" |
| 31 | AST-3-NO-DST | 180 | false | "(GMT+03:00) Iraq, Jordan, Kuwait" |
| 32 | AKST9 | -540 | true | "(GMT-09:00) Alaska" |
| 33 | MST7 | -420 | true | "(GMT-07:00) Mountain Time (USA & Canada)" |
| 34 | CLT4 | -240 | true | "(GMT-04:00) Chile Time (Chile, Antarctica)" |
| 35 | SAST-2-NO-DST | 120 | false | "(GMT+02:00) South Africa" |
| 36 | EET-2 | 120 | true | "(GMT+02:00) Greece, Ukraine, Romania, Turkey" |
| 37 | SGT-8-NO-DST | 480 | false | "(GMT+08:00) Singapore, Taiwan, Russia" |
| 38 | CST6-NO-DST | -360 | false | "(GMT-06:00) Mexico" |
| 39 | AST4 | -240 | true | "(GMT-04:00) Atlantic Time (Canada, Greenland, Atlantic Islands)" |

## 時區分佈分析

### 按UTC偏移分組：
- GMT-12: 1個 (MHT12-NO-DST)
- GMT-11: 1個 (WST11-NO-DST)
- GMT-10: 1個 (HST10-NO-DST)
- GMT-09: 1個 (AKST9)
- GMT-08: 1個 (PST8)
- GMT-07: 2個 (MST7-NO-DST, MST7)
- GMT-06: 2個 (CST6, CST6-NO-DST)
- GMT-05: 2個 (EST5-NO-DST, EST5)
- GMT-04: 3個 (VET4-NO-DST, CLT4, AST4)
- GMT-03:30: 1個 (NST03:30)
- GMT-03: 2個 (BRT3, ART3-NO-DST)
- GMT-02: 1個 (MAT2-NO-DST)
- GMT-01: 1個 (AZOT1)
- GMT+00: 2個 (GMT0-NO-DST, GMT0)
- GMT+01: 2個 (CET-1-NO-DST, CET-1)
- GMT+02: 2個 (SAST-2-NO-DST, EET-2)
- GMT+03: 1個 (AST-3-NO-DST)
- GMT+04: 1個 (GST-4-NO-DST)
- GMT+05: 1個 (PKT-5-NO-DST)
- GMT+05:30: 1個 (IST-05:30-NO-DST)
- GMT+06: 1個 (ALMT-6-NO-DST)
- GMT+07: 1個 (ICT-7-NO-DST)
- GMT+08: 2個 (HKT-8-NO-DST, SGT-8-NO-DST)
- GMT+09: 1個 (JST-9-NO-DST)
- GMT+10: 2個 (AEST-10, GST-10-NO-DST)
- GMT+11: 1個 (SBT-11-NO-DST)
- GMT+12: 2個 (FJT-12-NO-DST, NZST-12)

### DST 支援統計：
- 支援DST：15個 (38.5%)
- 不支援DST：24個 (61.5%)

### 特殊格式：
- 分數偏移：2個 (NST03:30, IST-05:30-NO-DST)
- 所有其他：整數小時偏移

## POSIX 轉換對應

根據 GitHub issue #12 的測試結果，SoC支援的POSIX格式：

### 簡單UTC格式（已驗證）：
- UTC-12, UTC-11, UTC-10, UTC-9, UTC-8, UTC-7, UTC-6, UTC-5, UTC-4, UTC-3, UTC-2, UTC-1
- UTC0, UTC+1, UTC+2, UTC+3, UTC+4, UTC+5, UTC+6, UTC+7, UTC+8, UTC+9, UTC+10, UTC+11, UTC+12

### 分數偏移格式（已驗證）：
- UTC-5:30 (對應IST-05:30-NO-DST)
- UTC+3:30 (對應NST03:30，但POSIX符號相反)

### 複雜DST格式（已驗證）：
- EST5EDT,M3.2.0/02:00,M11.1.0/02:00
- PST8PDT,M3.2.0/02:00,M11.1.0/02:00
- 等等...

## 實作要求

1. **完整覆蓋**：必須支援所有39個時區選項
2. **精確匹配**：timeZoneID 必須與 JSON 完全一致
3. **POSIX轉換**：自動轉換為路由器可接受的格式
4. **用戶友好**：顯示人類可讀的描述文本
5. **向後兼容**：支援現有的手動POSIX輸入方式