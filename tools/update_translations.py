import json
import os

# Translations for each language
translations ={
  "ar": {
    "wifiPasswordRuleHex": "مفتاح PSK سداسي عشري مطلوب (0-9، A-F، a-f)"
  },
  "da": {
    "wifiPasswordRuleHex": "Hexadecimal PSK påkrævet (0-9, A-F, a-f)"
  },
  "de": {
    "wifiPasswordRuleHex": "Hexadezimaler PSK erforderlich (0–9, A–F, a–f)"
  },
  "el": {
    "wifiPasswordRuleHex": "Απαιτείται δεκαεξαδικό PSK (0–9, A–F, a–f)"
  },
  "en": {
    "wifiPasswordRuleHex": "Hexadecimal PSK required (0–9, A–F, a–f)"
  },
  "es": {
    "wifiPasswordRuleHex": "Se requiere PSK hexadecimal (0–9, A–F, a–f)"
  },
  "es-AR": {
    "wifiPasswordRuleHex": "Se requiere PSK hexadecimal (0–9, A–F, a–f)"
  },
  "fi": {
    "wifiPasswordRuleHex": "Heksadesimaalinen PSK vaaditaan (0–9, A–F, a–f)"
  },
  "fr": {
    "wifiPasswordRuleHex": "PSK hexadécimal requis (0–9, A–F, a–f)"
  },
  "fr-CA": {
    "wifiPasswordRuleHex": "PSK hexadécimal requis (0–9, A–F, a–f)"
  },
  "id": {
    "wifiPasswordRuleHex": "PSK heksadesimal diperlukan (0–9, A–F, a–f)"
  },
  "it": {
    "wifiPasswordRuleHex": "PSK esadecimale richiesto (0–9, A–F, a–f)"
  },
  "ja": {
    "wifiPasswordRuleHex": "16進数PSKが必要です (0–9, A–F, a–f)"
  },
  "ko": {
    "wifiPasswordRuleHex": "16진수 PSK 필요 (0–9, A–F, a–f)"
  },
  "nb": {
    "wifiPasswordRuleHex": "Hexadesimal PSK påkrevd (0–9, A–F, a–f)"
  },
  "nl": {
    "wifiPasswordRuleHex": "Hexadecimale PSK vereist (0–9, A–F, a–f)"
  },
  "pl": {
    "wifiPasswordRuleHex": "Wymagany szesnastkowy klucz PSK (0–9, A–F, a–f)"
  },
  "pt": {
    "wifiPasswordRuleHex": "PSK hexadecimal necessário (0–9, A–F, a–f)"
  },
  "pt-PT": {
    "wifiPasswordRuleHex": "PSK hexadecimal necessário (0–9, A–F, a–f)"
  },
  "ru": {
    "wifiPasswordRuleHex": "Требуется шестнадцатеричный PSK (0–9, A–F, a–f)"
  },
  "sv": {
    "wifiPasswordRuleHex": "Hexadecimal PSK krävs (0–9, A–F, a–f)"
  },
  "th": {
    "wifiPasswordRuleHex": "ต้องระบุ PSK แบบเลขฐานสิบหก (0–9, A–F, a–f)"
  },
  "tr": {
    "wifiPasswordRuleHex": "Onaltılık PSK gerekli (0–9, A–F, a–f)"
  },
  "vi": {
    "wifiPasswordRuleHex": "Yêu cầu PSK hệ thập lục phân (0–9, A–F, a–f)"
  },
  "zh": {
    "wifiPasswordRuleHex": "需要十六进制 PSK (0–9, A–F, a–f)"
  },
  "zh_tw": {
    "wifiPasswordRuleHex": "需要十六進位 PSK (0–9, A–F, a–f)"
  }
}

def update_translations():
    # Construct the path to the 'lib/l10n' directory relative to the script's location
    # The script is in the 'tools' directory, so we need to go up one level to find 'lib/l10n'
    l10n_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'lib', 'l10n')

    # Ensure the l10n_dir exists
    if not os.path.isdir(l10n_dir):
        print(f"Error: Directory '{l10n_dir}' not found. Please ensure the script is in the correct location relative to your 'lib/l10n' folder.")
        return

    for filename in os.listdir(l10n_dir):
        # Process only app_*.arb files, excluding app_en.arb
        if not filename.startswith('app_') or not filename.endswith('.arb') or filename == 'app_en.arb':
            continue

        # Extract language code and normalize (convert to lowercase and replace - with _)
        # Example: 'app_es-AR.arb' becomes 'es_ar'
        lang_code = filename[4:-4].lower().replace('-', '_')

        # Adjust for 'es_ar' and 'fr_ca' if they are distinct in your translations dictionary
        if lang_code == 'es-ar': # handle potential direct match before _ conversion
            lang_code = 'es_AR'
        elif lang_code == 'fr-ca':
            lang_code = 'fr_CA'

        # Check if the exact language code exists in the translations dictionary
        if lang_code not in translations:
            # If not, try to fall back to the base language code (e.g., 'es' for 'es_AR')
            base_lang_code = lang_code.split('_')[0]
            if base_lang_code in translations:
                lang_code = base_lang_code
            else:
                print(f"No translations found for {lang_code}, skipping {filename}...")
                continue

        filepath = os.path.join(l10n_dir, filename)

        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Iterate through the keys in the translations dictionary for the current language
            for key, value in translations[lang_code].items():
                data[key] = value
                # Remove '@' prefixed keys associated with the updated key if they exist
                # These are typically metadata keys for the English file and shouldn't be in others.
                if f'@{key}' in data:
                    del data[f'@{key}']

            # Write back to file with proper indentation
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
                f.write('\n')  # Add newline at end of file

            print(f"Updated {filename}")

        except Exception as e:
            print(f"Error updating {filename}: {str(e)}")

if __name__ == '__main__':
    update_translations()