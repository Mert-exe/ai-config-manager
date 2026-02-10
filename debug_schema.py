import json
import jsonschema
from jsonschema import validate

# Dosyaları Yükle
try:
    with open(r"C:\\Users\\merte\\OneDrive\\Masaüstü\\intern-homework-master\\data\\values\\tournament.value.json", "r") as f:
        data = json.load(f)
    with open(r"C:\\Users\\merte\\OneDrive\\Masaüstü\\intern-homework-master\\data\\schemas\\tournament.schema.json", "r") as f:
        schema = json.load(f)

    print("Dosyalar yüklendi. Validasyon yapılıyor...")
    
    # Validasyon Testi
    validate(instance=data, schema=schema)
    print("✅ BAŞARILI: Dosya şemaya tam uyumlu!")

except jsonschema.ValidationError as e:
    print("\n HATA BULUNDU!")
    print(f"Hatalı Alan: {e.json_path}") # Hangi alanın bozuk olduğunu gösterir
    print(f"Hata Mesajı: {e.message}")
except Exception as e:
    print(f"Genel Hata: {e}")