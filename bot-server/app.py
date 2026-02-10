import requests
import json
import os
import ast
import re
import jsonschema
from jsonschema import validate
from flask import Flask, request, jsonify, abort

app = Flask(__name__)

# Konfigürasyon
SCHEMA_SERVICE_URL = os.environ.get("SCHEMA_SERVICE_URL", "http://localhost:5001")
VALUES_SERVICE_URL = os.environ.get("VALUES_SERVICE_URL", "http://localhost:5002")
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434/api/generate")
MODEL_NAME = os.environ.get("MODEL_NAME", "tinyllama") 

def extract_json(text):
    """Metin içinden JSON süslü parantezlerini cımbızla çeker."""
    try:
        text = text.replace("```json", "").replace("```", "").strip()
        s = text.find('{')
        e = text.rfind('}')
        if s != -1 and e != -1: return text[s:e+1]
        return text
    except: return text

def recursive_update(data, updates):
    """JSON ağacını gezer ve eşleşen anahtarları günceller."""
    updated_count = 0
    if isinstance(data, dict):
        for key in list(data.keys()):
            if key in updates:
                new_val = updates[key]
                # Metin içinden sayı temizleme (Örn: "1234mb" -> 1234)
                if isinstance(new_val, str) and not new_val.isdigit():
                     nums = re.findall(r'\d+', new_val)
                     if nums: new_val = int(nums[0])
                
                # Orijinal tip kontrolü ve dönüşüm
                try: 
                    if isinstance(data[key], (int, float)): new_val = int(new_val)
                except: pass

                data[key] = new_val
                print(f"INFO: Updated field '{key}' to {new_val}")
                updated_count += 1
            
            updated_count += recursive_update(data[key], updates)
            
    elif isinstance(data, list):
        for item in data:
            updated_count += recursive_update(item, updates)
    return updated_count

def query_ollama(prompt):
    try:
        payload = {
            "model": MODEL_NAME, "prompt": prompt, "stream": False,
            "options": {"temperature": 0.0, "num_predict": 128}
        }
        r = requests.post(OLLAMA_URL, json=payload, timeout=60)
        return r.json().get("response", "")
    except Exception as e:
        print(f"AI Error: {e}")
        return None

@app.route('/message', methods=['POST'])
def handle_message():
    data = request.get_json()
    if not data or 'input' not in data: abort(400)
    user_input = data['input']
    
    # --- ADIM 1: Uygulama İsmini Bul ---
    # Türkçe ve İngilizce isimleri eşleştiriyoruz
    app_map = {
        "tournament": "tournament",
        "turnuva": "tournament",
        "matchmaking": "matchmaking",
        "eşleştirme": "matchmaking",
        "chat": "chat",
        "sohbet": "chat"
    }
    
    app_name = "unknown"
    user_input_lower = user_input.lower()
    
    for key, val in app_map.items():
        if key in user_input_lower:
            app_name = val
            break
            
    if app_name == "unknown": abort(404, description="App name not found")

    #  ADIM 2: Mevcut Değerleri Çek 
    try:
        current_values = requests.get(f"{VALUES_SERVICE_URL}/{app_name}").json()
    except:
        abort(500, description="Values service unreachable")

    #  ADIM 3: Niyet Analizi (Few-Shot Prompt) 
    extract_prompt = f"""
    Task: Extract values from User Request and map to JSON keys.
    RULES:
    1. Extract the NUMBER from the request.
    2. Use REAL NUMBERS, not variable names.
    3. Mapping: 'memory' -> "limitMiB", "requestMiB" | 'cpu' -> "limitMilliCPU", "requestMilliCPU" | 'replicas' -> "replicas"

    EXAMPLES:
    User: "set memory to 1024" -> {{ "limitMiB": 1024, "requestMiB": 1024 }}
    User: "change replicas to 5" -> {{ "replicas": 5 }}

    User Request: "{user_input}"
    JSON:
    """
    
    ai_resp = query_ollama(extract_prompt)
    clean_resp = extract_json(ai_resp)
    
    updates = {}
    try:
        try: updates = json.loads(clean_resp)
        except: updates = ast.literal_eval(clean_resp)
    except:
        # Fallback: AI hata yaparsa Regex ile manuel deneme
        print("WARNING: AI JSON invalid. Switching to manual regex fallback.")
        nums = re.findall(r'\d+', user_input)
        if nums:
            val = int(nums[0])
            if "memory" in user_input.lower() or "bellek" in user_input.lower(): 
                updates = {"limitMiB": val, "requestMiB": val}
            elif "cpu" in user_input.lower(): 
                updates = {"limitMilliCPU": val, "requestMilliCPU": val}
            elif "replica" in user_input.lower(): 
                updates = {"replicas": val}
        else:
            # GÜVENLİK: Prompt Injection engelleme
            print(f"INFO: No valid numeric updates found in input. Ignoring request safely.")
            return jsonify(current_values)

    # ADIM 4: Güncelleme ve Doğrulama 
    if updates:
        # 1.Önce güncellemeyi uygula (hafızada)
        count = recursive_update(current_values, updates)
        
        if count > 0:
            # 2.Şemayı Çek (Schema Fetch) - README Gereksinimi
            try:
                schema_resp = requests.get(f"{SCHEMA_SERVICE_URL}/{app_name}")
                if schema_resp.status_code == 200:
                    app_schema = schema_resp.json()
                    
                    # 3.JSON Schema Validasyonu - README Gereksinimi
                    try:
                        validate(instance=current_values, schema=app_schema)
                        print("INFO: Schema validation successful.")
                    except jsonschema.ValidationError as e:
                        print(f"ERROR: Schema validation failed: {e.message}")
                        # Validasyon hatası varsa kaydetme, hata dön
                        return jsonify({
                            "status": "error",
                            "message": f"Schema validation failed: {e.message}",
                            "original_values": current_values
                        }), 400
                else:
                    print(f"WARNING: Schema not found for {app_name}, skipping validation.")
            except Exception as e:
                print(f"WARNING: Schema service unreachable: {e}")

            # 4.Validasyon geçtiyse (veya şema yoksa) kaydet
            requests.put(f"{VALUES_SERVICE_URL}/{app_name}", json=current_values)
    
    return jsonify(current_values)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003)