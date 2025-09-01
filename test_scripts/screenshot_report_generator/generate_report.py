import json
import os
import glob

def generate_report():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    report_data = []
    
    # Read all JSON files
    json_files = glob.glob(os.path.join(base_dir, "localizations-test-reports-*.json"))
    for json_file in json_files:
        with open(json_file, 'r') as f:
            data = json.load(f)
            report_data.extend(data)

    # Process data
    processed_data = []
    for item in report_data:
        locale = item.get('locale')
        device_type = item.get('deviceType')
        file_path = item.get('filePath')
        result = item.get('result')
        ts_name = item.get('tsName')
        messages = item.get('messages', [])

        if locale and device_type and file_path and result and ts_name:
            full_path = os.path.join(base_dir, file_path.lstrip('./'))
            # Standardize result: 'error' becomes 'failure'
            standardized_result = 'failure' if result == 'error' else result
            processed_data.append({
                'id': item.get('id'), # <--- ADD THIS LINE
                'name': ts_name,
                'locale': locale,
                'resolution': device_type,
                'imagePath': full_path,
                'result': standardized_result, # Use the standardized result
                'messages': messages
            })

    # Group data by locale and resolution
    grouped_data = {}
    for item in processed_data:
        locale = item['locale']
        resolution = item['resolution']
        if locale not in grouped_data:
            grouped_data[locale] = {}
        if resolution not in grouped_data[locale]:
            grouped_data[locale][resolution] = []
        grouped_data[locale][resolution].append(item)

    # Calculate summary statistics
    total_tests = len(processed_data)
    successful_tests = sum(1 for item in processed_data if item['result'] == 'success')
    failed_tests = total_tests - successful_tests

    # Calculate detailed statistics
    detailed_stats = {}
    for locale, resolutions in grouped_data.items():
        detailed_stats[locale] = {}
        for resolution, tests in resolutions.items():
            success_count = sum(1 for test in tests if test['result'] == 'success')
            fail_count = len(tests) - success_count
            detailed_stats[locale][resolution] = {
                'total': len(tests),
                'success': success_count,
                'failure': fail_count
            }

    # Generate detailed stats table rows
    detailed_stats_table_rows = []
    for locale, resolutions in detailed_stats.items():
        for resolution, stats in resolutions.items():
            detailed_stats_table_rows.append(f"""
                        <tr>
                            <td>{locale}</td>
                            <td>{resolution}</td>
                            <td>{stats['total']}</td>
                            <td>{stats['success']}</td>
                            <td>{stats['failure']}</td>
                        </tr>
            """)
    detailed_stats_table_rows_html = "\n".join(detailed_stats_table_rows)

    # Generate detailed charts HTML (now only a single canvas placeholder)
    # This part is removed as the canvas is now directly in the template
    # detailed_charts_html_content = ""

    # Generate locale options for filter
    locale_options = "\n".join([f'<option value="{locale}">{locale}</option>' for locale in sorted(grouped_data.keys())])

    # Generate resolution options for filter
    all_resolutions = sorted(list(set(r for l in grouped_data.values() for r in l.keys())))
    resolution_options = "\n".join([f'<option value="{res}">{res}</option>' for res in all_resolutions])

    # Read the template file
    with open(os.path.join(base_dir, "report_template.html"), "r", encoding="utf-8") as f:
        template_content = f.read()

    # Replace placeholders in the template
    final_html = template_content.replace("{{TOTAL_TESTS}}", str(total_tests))
    final_html = final_html.replace("{{SUCCESSFUL_TESTS}}", str(successful_tests))
    final_html = final_html.replace("{{FAILED_TESTS}}", str(failed_tests))
    final_html = final_html.replace("{{DETAILED_STATS_TABLE_ROWS}}", detailed_stats_table_rows_html)
    # Remove the detailed charts HTML placeholder replacement
    # final_html = final_html.replace("{{DETAILED_CHARTS_HTML}}", detailed_charts_html_content)
    final_html = final_html.replace("{{LOCALE_OPTIONS}}", locale_options)
    final_html = final_html.replace("{{RESOLUTION_OPTIONS}}", resolution_options)
    final_html = final_html.replace("{{ALL_DATA_JSON}}", json.dumps(grouped_data, indent=2))
    final_html = final_html.replace("{{DETAILED_STATS_JSON}}", json.dumps(detailed_stats, indent=2))

    # Write the final HTML to report.html
    with open(os.path.join(base_dir, "report.html"), "w", encoding="utf-8") as f:
        f.write(final_html)
    print("Report generated successfully at report.html")

generate_report()
