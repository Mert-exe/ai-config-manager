import argparse
import os
import json
from flask import Flask, jsonify, abort, request

app = Flask(__name__)

# Global variable to store values directory
VALUES_DIR = "/data/values"

@app.route('/<app_name>', methods=['GET'])
def get_values(app_name):
    target_file = f"{app_name}.value.json"
    values_path = os.path.join(VALUES_DIR, target_file)
    
    if not os.path.exists(values_path):
        # Try finding file with case-insensitive match if not found directly
        found = False
        for filename in os.listdir(VALUES_DIR):
            if filename.lower() == target_file.lower():
                values_path = os.path.join(VALUES_DIR, filename)
                found = True
                break
        
        if not found:
            abort(404, description="Values not found")
        
    try:
        with open(values_path, 'r') as f:
            values = json.load(f)
        return jsonify(values)
    except Exception as e:
        abort(500, description=str(e))

@app.route('/<app_name>', methods=['PUT', 'POST'])
def update_values(app_name):
    target_file = f"{app_name}.value.json"
    values_path = os.path.join(VALUES_DIR, target_file)
    
    # Check for case-insensitive match even for update to be safe
    if not os.path.exists(values_path):
        for filename in os.listdir(VALUES_DIR):
            if filename.lower() == target_file.lower():
                values_path = os.path.join(VALUES_DIR, filename)
                break
                
    try:
        new_values = request.get_json()
        if not new_values:
            abort(400, description="Missing JSON data")
            
        with open(values_path, 'w') as f:
            json.dump(new_values, f, indent=2)
        return jsonify({"status": "success", "message": f"Updated values for {app_name}"})
    except Exception as e:
        abort(500, description=str(e))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Values Service')
    # Default to local path for manual run. Docker should override this.
    parser.add_argument('--values-dir', default='data/values', help='Directory containing value files')
    parser.add_argument('--schema-dir', help='Alias for --values-dir', dest='values_dir_alias')
    parser.add_argument('--listen', default='0.0.0.0:5002', help='Host and port to listen on')
    args = parser.parse_args()

    if args.values_dir_alias:
        VALUES_DIR = args.values_dir_alias
    else:
        VALUES_DIR = args.values_dir

    host, port = args.listen.split(':')
    
    app.run(host=host, port=int(port))
