import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fully_shown.dart';

// The test font draws every glyph as a square as wide as the font size, so
// '192.168.1.100' at 10px needs 130px on one line.
const _ip = '192.168.1.100';
const _style = TextStyle(fontSize: 10, height: 1);

Widget _box(double width, Widget child, {double? height}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  testWidgets('a text that fits its box is fully shown', (tester) async {
    await tester.pumpWidget(_box(200, const Text(_ip, style: _style)));

    expect(find.text(_ip), isFullyShown);
  });

  testWidgets('a text whose glyphs are taller than its line is fully shown',
      (tester) async {
    // Arabic's and Thai's glyphs reach past the line they set. Here the line
    // is 5px tall and the glyphs 10px.
    await tester.pumpWidget(_box(
      200,
      const Text(_ip, style: TextStyle(fontSize: 10, height: 0.5)),
    ));

    expect(find.text(_ip), isFullyShown);
  });

  testWidgets('a text that wraps at a space is fully shown', (tester) async {
    // 'aaaa' and 'bbbb' are 40px each and fit a 45px line; the space the
    // first line ends on runs to 50px, but a space is not cut.
    await tester.pumpWidget(_box(45, const Text('aaaa bbbb', style: _style)));

    expect(find.text('aaaa bbbb'), isFullyShown);
  });

  testWidgets('an ellipsized text is not fully shown', (tester) async {
    await tester.pumpWidget(_box(
      80,
      const Text(_ip,
          style: _style, maxLines: 1, overflow: TextOverflow.ellipsis),
    ));

    expect(find.text(_ip), isNot(isFullyShown));
  });

  testWidgets('a text wider than its box is not fully shown', (tester) async {
    await tester.pumpWidget(_box(
      80,
      const Text(_ip,
          style: _style, softWrap: false, overflow: TextOverflow.clip),
    ));

    expect(find.text(_ip), isNot(isFullyShown));
  });

  testWidgets('a text taller than its box is not fully shown', (tester) async {
    // Two lines of 10px in a box 10px tall.
    await tester.pumpWidget(_box(
      80,
      height: 10,
      const Text(_ip, style: _style, overflow: TextOverflow.clip),
    ));

    expect(find.text(_ip), isNot(isFullyShown));
  });

  testWidgets('a text that an ancestor clips is not fully shown',
      (tester) async {
    // The text lays out at 200px, but the clip shows 80px of it.
    await tester.pumpWidget(_box(
      80,
      const ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: 200,
          child: Text(_ip, style: _style),
        ),
      ),
    ));

    expect(find.text(_ip), isNot(isFullyShown));
  });

  testWidgets('a text scrolled out of view is not fully shown', (tester) async {
    // The viewport is 100px tall. The second sliver starts at 60px, and the
    // text sits 50px into it, at 110px.
    await tester.pumpWidget(_box(
      200,
      height: 100,
      const CustomScrollView(slivers: [
        SliverToBoxAdapter(child: SizedBox(height: 60)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 50),
            child: Text(_ip, style: _style),
          ),
        ),
      ]),
    ));

    expect(find.text(_ip), isNot(isFullyShown));

    await tester.ensureVisible(find.text(_ip));
    await tester.pump();

    expect(find.text(_ip), isFullyShown);
  });

  testWidgets('a text below the screen is not fully shown', (tester) async {
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: 0,
          top: screen.height + 10,
          child: const Text(_ip, style: _style),
        ),
      ]),
    ));

    expect(find.text(_ip), isNot(isFullyShown));
  });

  // AppText(selectable: true) is a SelectableText, which draws with a
  // RenderEditable instead of a RenderParagraph.
  testWidgets('a selectable text that fits its box is fully shown',
      (tester) async {
    await tester
        .pumpWidget(_box(200, const SelectableText(_ip, style: _style)));

    expect(find.text(_ip), isFullyShown);
  });

  testWidgets(
      'a one-line selectable text wider than its box is not fully '
      'shown', (tester) async {
    // It scrolls sideways inside its box instead of wrapping.
    await tester.pumpWidget(
        _box(80, const SelectableText(_ip, style: _style, maxLines: 1)));

    expect(find.text(_ip), isNot(isFullyShown));
  });

  testWidgets('a failure says what cut the text', (tester) async {
    String failure(Finder finder) {
      try {
        expect(finder, isFullyShown);
      } on TestFailure catch (e) {
        return e.message!;
      }
      return '';
    }

    await tester.pumpWidget(_box(
      80,
      const Text(_ip,
          style: _style, maxLines: 1, overflow: TextOverflow.ellipsis),
    ));
    expect(failure(find.text(_ip)),
        contains('"192.168.1.100" is cut by maxLines or an ellipsis'));

    await tester.pumpWidget(_box(
      80,
      const Text(_ip,
          style: _style, softWrap: false, overflow: TextOverflow.clip),
    ));
    expect(failure(find.text(_ip)),
        contains('"192.168.1.100" needs 130.0×10.0 but its box is 80.0×10.0'));

    await tester.pumpWidget(_box(
      80,
      const ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: 200,
          child: Text(_ip, style: _style),
        ),
      ),
    ));
    expect(
        failure(find.text(_ip)),
        contains(
            '"192.168.1.100" is clipped to Rect.fromLTRB(0.0, 0.0, 80.0, '));
  });

  testWidgets('cutValues names each value that is cut, once scrolled to it',
      (tester) async {
    const mac = '8C:3B:AD:FE:EE:DD';
    await tester.pumpWidget(_box(
      80,
      height: 100,
      ListView(children: const [
        Text(_ip, style: _style, maxLines: 1, overflow: TextOverflow.ellipsis),
        // Below the 100px viewport until scrolled to.
        SizedBox(height: 300),
        Text(mac, style: _style),
      ]),
    ));

    expect(
      await cutValues(tester, {
        'IP': find.text(_ip),
        // A finder skips what is out of view unless told not to.
        'MAC': find.text(mac, skipOffstage: false),
        'SSID': find.text('Linksys03041'),
      }),
      [
        'IP: "192.168.1.100" is cut by maxLines or an ellipsis',
        'SSID: no text is there',
      ],
    );
  });

  testWidgets('a text that is not there is not fully shown', (tester) async {
    await tester.pumpWidget(_box(200, const Text(_ip, style: _style)));

    expect(find.text('10.0.0.1'), isNot(isFullyShown));
  });
}
