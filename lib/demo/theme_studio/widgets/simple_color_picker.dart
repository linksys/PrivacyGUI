import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const SimpleColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<SimpleColorPicker> createState() => _SimpleColorPickerState();
}

class _SimpleColorPickerState extends State<SimpleColorPicker> {
  late HSVColor _hsvColor;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(
      text: _toHex(widget.initialColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateColor(HSVColor color) {
    setState(() {
      _hsvColor = color;
      _hexController.text = _toHex(color.toColor());
    });
    widget.onColorChanged(color.toColor());
  }

  void _onHexChanged(String value) {
    if (value.length == 8) {
      try {
        final color = Color(int.parse('0x$value'));
        setState(() {
          _hsvColor = HSVColor.fromColor(color);
        });
        widget.onColorChanged(color);
      } catch (_) {}
    }
  }

  String _toHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: _hsvColor.toColor(),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(height: 16),

        // Hue
        _buildSlider(
          label: 'H',
          value: _hsvColor.hue,
          max: 360,
          onChanged: (v) => _updateColor(_hsvColor.withHue(v)),
          colors: [
            const Color(0xFFFF0000),
            const Color(0xFFFFFF00),
            const Color(0xFF00FF00),
            const Color(0xFF00FFFF),
            const Color(0xFF0000FF),
            const Color(0xFFFF00FF),
            const Color(0xFFFF0000),
          ],
        ),

        const SizedBox(height: 12),

        // Saturation
        _buildSlider(
          label: 'S',
          value: _hsvColor.saturation,
          max: 1.0,
          onChanged: (v) => _updateColor(_hsvColor.withSaturation(v)),
          colors: [
            Colors.white,
            HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, _hsvColor.value)
                .toColor(),
          ],
        ),

        const SizedBox(height: 12),

        // Value
        _buildSlider(
          label: 'V',
          value: _hsvColor.value,
          max: 1.0,
          onChanged: (v) => _updateColor(_hsvColor.withValue(v)),
          colors: [
            Colors.black,
            HSVColor.fromAHSV(1.0, _hsvColor.hue, _hsvColor.saturation, 1.0)
                .toColor(),
          ],
        ),

        const SizedBox(height: 16),

        // Hex Input
        TextField(
          controller: _hexController,
          decoration: const InputDecoration(
            labelText: 'Hex (AARRGGBB)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          style: const TextStyle(fontFamily: 'monospace'),
          onChanged: _onHexChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
            LengthLimitingTextInputFormatter(8),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
    required List<Color> colors,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 24,
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12, elevation: 2),
                overlayShape: SliderComponentShape.noOverlay,
                thumbColor: Colors.white,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
              ),
              child: Slider(
                value: value,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
