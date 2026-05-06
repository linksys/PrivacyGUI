# Device-Specific Theme Files

This directory contains device-specific theme JSON files that are automatically loaded based on the router model number.

## How It Works

When the app connects to a router, `ThemeConfigLoader` checks the device model number and loads the corresponding theme file:

```
ThemeConfigLoader._resolveDeviceTheme(modelNumber)
  → Match model prefix to suffix
  → Load assets/theme/theme{suffix}.json
  → Fallback to defaultConfig() if not found
```

## File Naming Convention

| Model Prefix | Suffix | File Name |
|--------------|--------|-----------|
| `TB-` | `_tb` | `theme_tb.json` |
| `CF-` | `_cf` | `theme_cf.json` |
| `DU-` | `_du` | `theme_du.json` |

The mapping is defined in `lib/theme/theme_config_loader.dart`:

```dart
static const Map<String, String> _modelSuffixMap = {
  'TB-': '_tb',
  'CF-': '_cf',
  'DU-': '_du',
};
```

## Theme JSON Structure

Each theme file follows the `ThemeJsonConfig.fromJson` schema:

```json
{
  "style": "flat",
  "seedColor": "#6750A4",
  "visualEffects": 0,
  "globalOverlay": "none",
  "colors": {
    "light": {
      "primary": "#2196F3",
      "secondary": "#FF9800"
    },
    "dark": {
      "primary": "#90CAF9",
      "secondary": "#FFB74D"
    }
  },
  "overrides": {
    "surfaceStyle": {
      "base": { "borderRadius": 16.0 }
    },
    "componentStyle": {
      "button": { "borderRadius": 12.0 }
    }
  }
}
```

### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `style` | string | Design style: `glass`, `flat`, `brutal`, `neumorphic`, `pixel`, `aurora` |
| `seedColor` | string | Hex color for Material 3 color scheme generation |
| `visualEffects` | int | Bitmask for visual effects |
| `globalOverlay` | string | `none`, `noiseOverlay`, `crtShader`, `auroraGlow`, `snow`, `hacker` |
| `colors.light` | object | Light theme color overrides |
| `colors.dark` | object | Dark theme color overrides |
| `overrides` | object | Structural overrides for surfaces and components |

See [UI Kit THEME_STANDARD.md](../../../ui_kit_library/docs/THEME_STANDARD.md) for full override options.

## Override Priority

Device themes are only loaded when NO override is active. Override priority (highest to lowest):

1. **CI/CD** (`THEME_JSON` env var) - Direct JSON string injection
2. **Network** (`THEME_NETWORK_URL` env var) - Remote download (reserved)
3. **Assets** (`THEME_ASSET_PATH` env var) - Specific asset file (default: `assets/theme.json`)
4. **Device Theme** - This directory, based on model number
5. **Default** - Built-in fallback theme (`flat` style)

## Adding a New Device Theme

1. Create `theme_{suffix}.json` in this directory
2. Add the model prefix mapping to `_modelSuffixMap` in `theme_config_loader.dart`
3. The directory is already declared in `pubspec.yaml` under `assets:`

## Related Documentation

- [Theme Architecture](../../doc/theme/theme_architecture.md) - Full loading flow documentation
- [ThemeConfigLoader](../../lib/theme/theme_config_loader.dart) - Implementation
- [ThemeJsonConfig](../../lib/theme/theme_json_config.dart) - Data model
