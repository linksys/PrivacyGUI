part of 'combine_results.dart';

String generateHTMLReport(Map<String, dynamic> result, String version) {
  return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Linksys Now Screenshots Report $version</title>
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

    .report-table {
      width: 100%;
    }

    .group-name {
      font-weight: bold;
      font-size: .8em;
      margin-top: 1em;
      border-bottom: 1px solid #ccc;
      padding-bottom: 0.5em;
      background-color: #f2f2f2; /* Light gray background for group names */
    }

    .locale-header {  /* New style for locale headers */
      font-weight: bold;
      font-size: 1.5em;
      margin-top: 0.5em;
      margin-bottom: 0.5em;
      background-color: #e6f2ff; /* Light blue background for locale headers */
    }

    .testcase-header {
      font-style: italic;
      margin-bottom: 0.5em;
      background-color: #f9f9f9; /* Very light gray background for test cases */
    }
  </style>
  <style>
    .chart-container {
        width: 200px;
        height: 200px;
        position: relative;
    }
    .legend {
        margin-top: 20px;
    }
    .legend-item {
        display: flex;
        align-items: center;
        margin: 5px 0;
    }
    .color-box {
        width: 20px;
        height: 20px;
        margin-right: 10px;
    }
  </style>
  <body onload="init()">
    <script>
      const resultJson = ${jsonEncode(result)};
      
      function init() {
        // initalize filters, regarding locales and devices on resultJson
        initFilters(resultJson);
        // make default classify and render table
        defaultClassify();
      }
      function initFilters(resultJson) {
        // Extract unique locales and device types from resultJson
        const locales = new Set();
        const deviceTypes = new Set();
        const results = new Set();

        resultJson.tests.forEach(test => {
          locales.add(test.locale);
          deviceTypes.add(test.deviceType);
          results.add(test.result);
        });
        locales.delete(undefined);
        deviceTypes.delete(undefined);

        // Create filter elements for locales
        const localeFilters = document.createElement('div');
        localeFilters.innerHTML = '<h3>Locale:</h3>';
        locales.forEach(locale => {
          const checkbox = document.createElement('input');
          checkbox.type = 'checkbox';
          checkbox.id = `locale-\${locale}`;
          checkbox.name = 'locale';
          checkbox.value = locale;
          checkbox.checked = true; // Initially all locales are selected
          checkbox.addEventListener('change', defaultClassify);

          const label = document.createElement('label');
          label.htmlFor = `locale-\${locale}`;
          label.textContent = locale;

          localeFilters.appendChild(checkbox);
          localeFilters.appendChild(label);
        });
        document.querySelector('.filters').appendChild(localeFilters);


        // Create filter elements for device types
        const deviceTypeFilters = document.createElement('div');
        deviceTypeFilters.innerHTML = '<h3>Device Type:</h3>';
        deviceTypes.forEach(deviceType => {
          const checkbox = document.createElement('input');
          checkbox.type = 'checkbox';
          checkbox.id = `deviceType-\${deviceType}`;
          checkbox.name = 'deviceType';
          checkbox.value = deviceType;
          checkbox.checked = true; // Initially all device types are selected
          checkbox.addEventListener('change', defaultClassify);

          const label = document.createElement('label');
          label.htmlFor = `deviceType-\${deviceType}`;
          label.textContent = deviceType;

          deviceTypeFilters.appendChild(checkbox);
          deviceTypeFilters.appendChild(label);
        });
        document.querySelector('.filters').appendChild(deviceTypeFilters);

        // Create filter elements for results
        const resultFilters = document.createElement('div');
        resultFilters.innerHTML = '<h3>Result:</h3>';
        results.forEach(result => {
          const checkbox = document.createElement('input');
          checkbox.type = 'checkbox';
          checkbox.id = `result-\${result}`;
          checkbox.name = 'result';
          checkbox.value = result;
          checkbox.checked = true; // Initially all results are selected
          checkbox.addEventListener('change', defaultClassify);

          const label = document.createElement('label');
          label.htmlFor = `result-\${result}`;
          label.textContent = result;

          resultFilters.appendChild(checkbox);
          resultFilters.appendChild(label);
        });
        document.querySelector('.filters').appendChild(resultFilters);

        document.querySelector('.filters').appendChild(document.createElement('br'));

      }
      
      function defaultClassify() {
        const selectedLocales = Array.from(document.querySelectorAll('input[name="locale"]:checked')).map(checkbox => checkbox.value);
        
        const selectedDeviceTypes = Array.from(document.querySelectorAll('input[name="deviceType"]:checked')).map(checkbox => checkbox.value);
      
        const selectedResults = Array.from(document.querySelectorAll('input[name="result"]:checked')).map(checkbox => checkbox.value);

        const filteredTests = resultJson.tests.filter(test => selectedLocales.includes(test.locale) && selectedDeviceTypes.includes(test.deviceType) && selectedResults.includes(test.result));
        
        // counting success and fail test cases and put data into classified obj
        const successCount = filteredTests.filter(test => test.result === 'success').length;
        const failCount = filteredTests.filter(test => test.result === 'error').length;
        var countingObj = {
          'success': successCount,
          'fail': failCount,
          'total': successCount + failCount

        }
        
        // classify by locale, then testCaseFilePath, then groupName
        var classified = {};
        for (var i = 0; i < filteredTests.length; i++) {
          var result = filteredTests[i];
          var locale = result.locale;
          var testCaseFilePath = result.testCaseFilePath;
          var groupName = result.groupName;
          if (!classified[locale]) {
            classified[locale] = {};
          }
          if (!classified[locale][testCaseFilePath]) {
            classified[locale][testCaseFilePath] = {};
          }
          if (!classified[locale][testCaseFilePath][groupName]) {
            classified[locale][testCaseFilePath][groupName] = [];
          }
          classified[locale][testCaseFilePath][groupName].push(result);
        }
        createTestReports(classified, countingObj);
      }
    
      function createTestReports(classified, counting) {
          generateChart(counting);

          // Clear existing reports
          const reportsDiv = document.querySelector('.reports');
          reportsDiv.innerHTML = '';

          for (const locale in classified) {
              const table = document.createElement('table');
              table.classList.add('report-table'); // Add a class to the table for styling
      
              // Locale header row
              const localeHeaderRow = table.insertRow();
              localeHeaderRow.classList.add('locale-header'); // Add class for styling
              const localeHeaderCell = localeHeaderRow.insertCell();
              localeHeaderCell.textContent = locale;
              localeHeaderCell.colSpan = 2;
      
              for (const testCaseFilePath in classified[locale]) {
                  // Test Case File Path header row 
                  const testCaseHeaderRow = table.insertRow();
                  testCaseHeaderRow.classList.add('testcase-header'); // Add class for styling
                  const testCaseHeaderCell = testCaseHeaderRow.insertCell();
                  testCaseHeaderCell.textContent = testCaseFilePath;
                  testCaseHeaderCell.colSpan = 2;
      
                  for (const groupName in classified[locale][testCaseFilePath]) {
                      const groupNameRow = table.insertRow();
                      groupNameRow.classList.add('group-name'); // Add class for styling
                      const groupNameCell = groupNameRow.insertCell();
                      groupNameCell.textContent = groupName;
                      groupNameCell.colSpan = 2;
      
                      // Result header row (moved inside the groupName loop)
                      const headerRow = table.insertRow();
                      headerRow.classList.add('result-header'); // Add a class to the header row
                      const headers = ['name', 'result'];
                      headers.forEach(headerText => {
                          const th = document.createElement('th');
                          th.textContent = headerText;
                          headerRow.appendChild(th);
                      });
      
                      for (const result of classified[locale][testCaseFilePath][groupName]) {
                          const row = table.insertRow();
                          row.classList.add(result.result); // Add result class directly to the row
      
      
                          const nameTd = row.insertCell(); // Use insertCell on the row
                          const link = document.createElement('a');
                          link.href = result.filePath;
                          link.textContent = result.name;
                          nameTd.appendChild(link);
      
      
                          const resultTd = row.insertCell();// Use insertCell on the row
                          resultTd.textContent = result.result;
      
      
                      }
      
                  }
              }
              reportsDiv.appendChild(table);
              reportsDiv.appendChild(document.createElement('br'));
          }

          const localeHeaders = document.querySelectorAll('.locale-header');
            localeHeaders.forEach(header => {
              header.addEventListener('click', () => {
                  var nextSibling = header.nextElementSibling;
                  while (nextSibling && !nextSibling.classList.contains('locale-header')) {
                      if (nextSibling.style.display === 'none') {
                          nextSibling.style.display = '';
                      } else {
                          nextSibling.style.display = 'none';
                      }
                      nextSibling = nextSibling.nextElementSibling;
                    
                  }
              });
            });
      }

      function generateChart(data) {
        const total = data.total;
        const success = data.success;
        const fail = data.fail;

        // Calculate percentages
        const successPercent = (success / total) * 100.0;
        const failPercent = (fail / total) * 100.0;
        const countingData = [
          {label: 'Success', value: successPercent, color:'#1e7145'},
          {label: 'Fail', value: failPercent, color:'#b91d47'}

        ];

        const totalCountDiv = document.querySelector('.totalCount');
        totalCountDiv.innerHTML = total;
        const totalPercentDiv = document.querySelector('.totalPercent');
        totalPercentDiv.innerHTML = '100%';
        const successCount = document.querySelector('.successCount');
        successCount.innerHTML = success;
        const successPercentDiv = document.querySelector('.successPercent');
        successPercentDiv.innerHTML = successPercent.toFixed(2) + '%';
        const failCount = document.querySelector('.failCount');
        failCount.innerHTML = fail;
        const failPercentDiv = document.querySelector('.failPercent');
        failPercentDiv.innerHTML = failPercent.toFixed(2) + '%';

        // Initialize the chart
        const canvas = document.getElementById('donutChart');
        drawDonutChart(countingData, canvas);

        const legendContainer = document.getElementById('legend');
        createLegend(countingData, legendContainer);
    }

    function drawDonutChart(data, canvas) {
        const ctx = canvas.getContext('2d');
        const centerX = canvas.width / 2;
        const centerY = canvas.height / 2;
        const radius = Math.min(centerX, centerY) * 0.8;
        const innerRadius = radius * 0.6; // This creates the donut hole

        // Calculate total for percentages
        const total = data.reduce((sum, item) => sum + item.value, 0);

        let currentAngle = -0.5 * Math.PI; // Start at top

        // Draw the segments
        data.forEach(item => {
            const sliceAngle = (2 * Math.PI * item.value) / total;

            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, currentAngle, currentAngle + sliceAngle);
            ctx.arc(centerX, centerY, innerRadius, currentAngle + sliceAngle, currentAngle, true);
            ctx.closePath();

            ctx.fillStyle = item.color;
            ctx.fill();

            // Add white border
            ctx.strokeStyle = 'white';
            ctx.lineWidth = 2;
            ctx.stroke();

            currentAngle += sliceAngle;
        });
    }

    function createLegend(data, container) {
        container.innerHTML = '';

        const total = data.reduce((sum, item) => sum + item.value, 0);
        
        data.forEach(item => {
            const percentage = ((item.value / total) * 100).toFixed(2);
            const legendItem = document.createElement('div');
            legendItem.className = 'legend-item';
            
            const colorBox = document.createElement('div');
            colorBox.className = 'color-box';
            colorBox.style.backgroundColor = item.color;
            
            const label = document.createElement('span');
            label.textContent = `\${item.label} (\${percentage}%)`;
            
            legendItem.appendChild(colorBox);
            legendItem.appendChild(label);
            container.appendChild(legendItem);
        });
    }

    </script>

    <h1>Linksys Now $version Screenshots Report</h1>
    <table style="width:100%">
      <tr>
        <th>Total</th>
        <td class="totalCount textCenter"></td>
        <td class="totalPercent textCenter"></td>
        <td rowSpan="3">
          <canvas id="donutChart" width="400" height="400"></canvas>
          <div id="legend" class="legend"></div>
        </td>
      </tr>
      <tr>
        <th>Success</th>
        <td class="successCount textCenter"></td>
        <td class="successPercent textCenter"></td>
      </tr>
      <tr>
        <th>Fail</th>
        <td class="failCount textCenter"></td>
        <td class="failPercent textCenter"></td>
      </tr>
    </table>
    <br/>
    <div class="filters"></div>
    <div class="reports"></div>
  </body>
</html>
''';
}
