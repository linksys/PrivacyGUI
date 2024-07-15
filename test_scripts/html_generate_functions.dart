part of 'test_result_parser.dart';

String generateHTMLReport(Map<String, dynamic> result) {
  return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Test Report</title>
    <link rel="stylesheet" href="style.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.9.4/Chart.js"></script>
  </head>
  <style>
    .success {
      color: green;
    }
    .failed {
      color: red;
    }
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
      text-align: start;
      padding: 1rem;
    }
    .textCenter {
      text-align: center !important;
    }
    .wrapword {
      white-space: -moz-pre-wrap !important;  /* Mozilla, since 1999 */
      white-space: -pre-wrap;      /* Opera 4-6 */
      white-space: -o-pre-wrap;    /* Opera 7 */
      white-space: pre-wrap;       /* css-3 */
      word-wrap: break-word;       /* Internet Explorer 5.5+ */
      white-space: -webkit-pre-wrap; /* Newer versions of Chrome/Safari*/
      word-break: break-all;
      white-space: normal;
    }
  </style>
  <body>
    <script src="index.js"></script>
    <h1>Test Report</h1>
    <table style="width:100%">
      <tr>
        <th>Total</th>
        <td class="textCenter">${result['counting']['total']}</td>
        <td class="textCenter">${formatPercentage((result['counting']['total'] / result['counting']['total']) * 100, 2)}%</td>
        <td rowSpan="3">
          <canvas id="myChart" style="width:100%;max-width:600px"></canvas>
        </td>
      </tr>
      <tr>
        <th>Success</th>
        <td class="textCenter">${result['counting']['success']}</td>
        <td class="textCenter">${formatPercentage((result['counting']['success'] / result['counting']['total']) * 100, 2)}%</td>
      </tr>
      <tr>
        <th>Fail</th>
        <td class="textCenter">${result['counting']['fail']}</td>
        <td class="textCenter">${formatPercentage((result['counting']['fail'] / result['counting']['total']) * 100, 2)}%</td>
      </tr>
    </table>
    <br/>
    ${(result['suites'] as List<Map<String, dynamic>>).map((e) => generateHTMLSuite(e)).toList().join()}

    <script>
      \$(".clickable").click(function() {
        var next = \$(this).next();
        while(next.length > 0 && !next.hasClass('clickable')) {
          next.toggle();
          next = next.next();
        }
      });
    </script>
    <script>
      var xValues = ["Success", "Fail"];
      var yValues = [${result['counting']['success']}, ${result['counting']['fail']}];
      var barColors = [
        "#1e7145",
        "#b91d47"
      ];

      new Chart("myChart", {
        type: "doughnut",
        data: {
          labels: xValues,
          datasets: [{
            backgroundColor: barColors,
            data: yValues
          }]
        },
        options: {

        }
      });
    </script>
  </body>
</html>
''';
}

String generateHTMLSuite(Map<String, dynamic> suite) {
  return '''
  <table style="width:100%">
    <tr class="clickable" style="background:beige;">
      <th style="width:80%" class="wrapword">${suite['path']}</th>
      <th style="width:20%" class="textCenter">${suite['total']}</th>
    </tr>
    ${(suite['groups'] as List<Map<String, dynamic>>).map((e) => generateHTMLGroup(e)).toList().join()}
  </table>
''';
}

String generateHTMLGroup(Map<String, dynamic> group) {
  return '''
  <tr style="background: ghostwhite;">
    <td style="width:80%;text-indent:10px">${group['name'] == '' ? "All tests" : group['name']}</th>
    <td class="textCenter" style="width:20%">${group['testCount']}</th>
  </tr>
  ${(group['tests'] as List<Map<String, dynamic>>).where((element) => element['result'] != null).map((e) => generateHTMLTest(e)).toList().join()}
''';
}

String generateHTMLTest(Map<String, dynamic> test) {
  final name = test['name'];
  final regex = RegExp(r'(.*) \(variant: (.*)-(.*)_.*');
  final match = regex.firstMatch(name);
  final tsName = match?.group(1)?.trim();
  final deviceType = match?.group(2);
  final locale = match?.group(3);
  String? link;
  if (tsName != null && locale != null && deviceType != null) {
    link = './$locale/$deviceType/$tsName-$deviceType-$locale.png';
  }
  final nameTdScript =
      link == null ? '${test['name']}' : '<a href="$link">${test['name']}</a>';
  final skip = test['metadata']?['skip'] ?? false;
  final result = skip ? 'Skip' : '${test['result']}';
  return '''
  <tr>
    <td style="width:80%;text-indent:20px" >$nameTdScript</th>
    <td style="width:20%" class="textCenter $result">$result</th>
  </tr>
''';
}
