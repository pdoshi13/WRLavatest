#!/usr/bin/env python3
import json
import os
import argparse
from jinja2 import Environment, FileSystemLoader
from collections import defaultdict
import html
import socket
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler
import webbrowser
import warnings

def read_log_file(log_path):
    try:
        with open(os.path.join(log_path, 'stdout.log'), 'r') as f:
            return f.read()
    except:
        return "Log file not found"

def calculate_test_summary(metrics):
    total = len(metrics)
    passed = sum(1 for m in metrics if m['result'] == 'pass')
    failed = sum(1 for m in metrics if m['result'] == 'fail')
    skipped = sum(1 for m in metrics if m['result'] == 'skip')
    pass_rate = (passed / total * 100) if total > 0 else 0
    return {
        'total': total,
        'pass': passed,
        'fail': failed,
        'skip': skipped,
        'pass_rate': pass_rate
    }

def calculate_overall_summary(processed_data):
    summary = {'pass': 0, 'fail': 0, 'skip': 0, 'total': 0}
    for tests in processed_data.values():
        for test in tests:
            summary['pass'] += test['summary']['pass']
            summary['fail'] += test['summary']['fail']
            summary['skip'] += test['summary']['skip']
            summary['total'] += test['summary']['total']
    summary['pass_rate'] = (summary['pass'] / summary['total'] * 100) if summary['total'] > 0 else 0
    return summary

def process_test_directory(input_dir):
    if not os.path.exists(input_dir):
        return defaultdict(list)
    
    result_file = os.path.join(input_dir, 'result.json')
    if not os.path.exists(result_file):
        warnings.warn(f"Result file not found: {result_file}")
        return defaultdict(list)

    try:
        with open(result_file, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        warnings.warn(f"Error parsing result.json in {input_dir}: {str(e)}")
        return defaultdict(list)
    except Exception as e:
        warnings.warn(f"Error reading result.json in {input_dir}: {str(e)}")
        return defaultdict(list)

    processed_data = defaultdict(list)
    for test in data:
        test_dir = os.path.join(input_dir, test['id'])
        log_content = read_log_file(test_dir)

        params = {k: str(v) for k, v in test['params'].items() if v is not None}
        test_summary = calculate_test_summary(test['metrics'])

        test_info = {
            'id': test['id'],
            'params': params,
            'name': test['name'],
            'metrics': test['metrics'],
            'log_content': html.escape(log_content),
            'log_path': test_dir,
            'summary': test_summary
        }
        processed_data[test['test']].append(test_info)

    return processed_data

def process_multiple_directories(input_dirs):
    test_suites = []
    test_data = {}
    
    # First, check which directories exist and print summary
    existing_dirs = []
    missing_dirs = []
    for input_dir in input_dirs:
        input_dir = input_dir.strip()
        if not input_dir:
            continue
        if os.path.exists(input_dir):
            existing_dirs.append(input_dir)
        else:
            missing_dirs.append(input_dir)
    
    if missing_dirs:
        print("Following directories were not found and will be skipped:\n", "\n ".join(missing_dirs))
    
    if existing_dirs:
        print("\nWill process reports from:\n", "\n ".join(existing_dirs))
    else:
        print("No valid directories found to process")

    for input_dir in input_dirs:
        input_dir = input_dir.strip()
        if not input_dir:
            continue

        suite_name = os.path.basename(input_dir.rstrip('/'))
        display_name = suite_name.replace('output_', '')

        processed_data = process_test_directory(input_dir)
        if not processed_data:
            continue

        summary = calculate_overall_summary(processed_data)

        test_list = []
        for test_type, tests in processed_data.items():
            for test in tests:
                test_list.append({
                    'test_type': test_type,
                    'id': test['id'],
                    'name': test['name'],
                    'params': test['params'],
                    'metrics': test['metrics'],
                    'log_content': test['log_content'],
                    'summary': test['summary']
                })

        test_suites.append({
            'name': suite_name,
            'display_name': display_name,
            'summary': summary
        })

        test_data[suite_name] = test_list

    return test_suites, test_data

def generate_html(input_dirs, output_file, template_path):
    if not os.path.exists(template_path):
        warnings.warn(f"Template file not found: {template_path}")
        return False

    test_suites, test_data = process_multiple_directories(input_dirs)
    
    if not test_suites:
        warnings.warn("No valid test suites found to process")
        return False

    try:
        env = Environment(loader=FileSystemLoader(os.path.dirname(template_path)))
        template = env.get_template(os.path.basename(template_path))

        html_content = template.render(
            test_suites=test_suites,
            test_data=test_data
        )

        os.makedirs(os.path.dirname(os.path.abspath(output_file)), exist_ok=True)
        with open(output_file, 'w') as f:
            f.write(html_content)
        return True
    except Exception as e:
        warnings.warn(f"Error generating HTML report: {str(e)}")
        return False

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def start_http_server(directory, port=8000):
    os.chdir(directory)
    handler = SimpleHTTPRequestHandler
    httpd = HTTPServer(('', port), handler)
    server_thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    server_thread.start()
    return httpd, server_thread

def generate_link(ip, port, output_file):
    filename = os.path.basename(output_file)
    return f"http://{ip}:{port}/{filename}"

def main():
    parser = argparse.ArgumentParser(description='Generate HTML test report from test results')
    parser.add_argument('--input-dir', required=True,
                      help='Comma-separated list of input directories containing test results')
    parser.add_argument('--output-html', required=True, help='Output HTML file path')
    parser.add_argument('--template', required=True, help='Path to HTML template file')
    parser.add_argument('--serve', action='store_true', help='Serve the generated HTML via HTTP server')

    args = parser.parse_args()

    input_dirs = [dir.strip() for dir in args.input_dir.split(',')]
    success = generate_html(input_dirs, args.output_html, args.template)
    
    if success:
        print(f"HTML report generated: {args.output_html}")

        if args.serve:
            output_abs_path = os.path.abspath(args.output_html)
            serve_directory = os.path.dirname(output_abs_path)

            port = 8000
            httpd, server_thread = start_http_server(serve_directory, port)

            ip = get_local_ip()
            link = generate_link(ip, port, args.output_html)
            print(f"Serving HTML report at: {link}")

            try:
                webbrowser.open(link)
            except:
                pass

            print("HTTP server is running. Press Ctrl+C to stop.")
            try:
                server_thread.join()
            except KeyboardInterrupt:
                print("\nShutting down the server...")
                httpd.shutdown()
    else:
        print("Failed to generate HTML report due to errors. Check warnings above.")

if __name__ == "__main__":
    main()
