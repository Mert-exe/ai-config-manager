import argparse
import os
import json
from flask import Flask, jsonify, abort

app = Flask(__name__)

# Global variable to store schema directory
SCHEMA_DIR = "/data/schemas"

@app.route('/<app_name>', methods=['GET'])
def get_schema(app_name):
    target_file = f"{app_name}.schema.json"
    schema_path = os.path.join(SCHEMA_DIR, target_file)
    
    if not os.path.exists(schema_path):
        # Case-insensitive lookup
        found = False
        if os.path.exists(SCHEMA_DIR):
            for filename in os.listdir(SCHEMA_DIR):
                if filename.lower() == target_file.lower():
                    schema_path = os.path.join(SCHEMA_DIR, filename)
                    found = True
                    break
        
        if not found:
            abort(404, description="Schema not found")
        
    try:
        with open(schema_path, 'r') as f:
            schema = json.load(f)
        return jsonify(schema)
    except Exception as e:
        abort(500, description=str(e))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Schema Service')
    # Default to local path for manual run. Docker should override this.
    parser.add_argument('--schema-dir', default='data/schemas', help='Directory containing schema files')
    parser.add_argument('--listen', default='0.0.0.0:5001', help='Host and port to listen on')
    args = parser.parse_args()

    SCHEMA_DIR = args.schema_dir
    host, port = args.listen.split(':')
    
    app.run(host=host, port=int(port))
