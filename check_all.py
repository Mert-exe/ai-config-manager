import json
import os
try:
    from jsonschema import validate, ValidationError
except ImportError:
    print("Lütfen önce 'pip install jsonschema' çalıştırın.")
    exit()

# Docker dışından çalıştırıyorsak yol data/... olabilir, 
# ama proje kök dizinindeysen direkt data klasörüne bakarız.
BASE_DIR = "data" 

apps = ["tournament", "matchmaking", "chat"]

print("\n JSON SCHEMA VALIDATION SCAN STARTING...\n")

for app in apps:
    print(f"--- Checking App: {app.upper()} ---")
    try:
        s_path = os.path.join(BASE_DIR, "schemas", f"{app}.schema.json")
        v_path = os.path.join(BASE_DIR, "values", f"{app}.value.json")
        
        if not os.path.exists(s_path) or not os.path.exists(v_path):
            print(f"  Files not found for {app}. Skipping.")
            continue

        with open(s_path, 'r', encoding='utf-8') as f: schema = json.load(f)
        with open(v_path, 'r', encoding='utf-8') as f: values = json.load(f)
        
        validate(instance=values, schema=schema)
        print(f" {app}.value.json is VALID.")
        
    except ValidationError as e:
        print(f" {app}.value.json is INVALID!")
        print(f"   -> Error Location: {e.json_path}")
        print(f"   -> Error Message:  {e.message}")
    except Exception as e:
        print(f"  System Error: {e}")
    print("-" * 30)