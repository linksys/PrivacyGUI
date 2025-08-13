import json
import os
import sys

def update_translations(translations_file_path=None):
    """
    Updates translation files (*.arb) in the 'lib/l10n' directory.

    Args:
        translations_file_path (str, optional): The path to the external JSON file
                                                containing the translations. If not
                                                provided, it defaults to 'translated.json'
                                                in the same directory as the script.
    """
    # Determine the path for the translations file
    script_dir = os.path.dirname(__file__)
    if translations_file_path is None:
        translations_file = os.path.join(script_dir, 'translated.json')
    else:
        translations_file = translations_file_path

    # Load translations from the external JSON file
    try:
        with open(translations_file, 'r', encoding='utf-8') as f:
            translations = json.load(f)
    except FileNotFoundError:
        print(f"Error: The translations file '{translations_file}' was not found.")
        return
    except json.JSONDecodeError:
        print(f"Error: The translations file '{translations_file}' is not a valid JSON file.")
        return

    # Construct the path to the 'lib/l10n' directory
    l10n_dir = os.path.join(os.path.dirname(script_dir), 'lib', 'l10n')

    # Ensure the l10n_dir exists
    if not os.path.isdir(l10n_dir):
        print(f"Error: Directory '{l10n_dir}' not found. Please ensure the script is in the correct location relative to your 'lib/l10n' folder.")
        return
    
    # Pre-process translations dictionary for easier lookup
    normalized_keys = {}
    for key in translations.keys():
        normalized_keys[key] = key
        # Add a lowercased version
        normalized_keys[key.lower()] = key
        # Add variations with '-' replaced by '_'
        normalized_keys[key.replace('-', '_')] = key
        # Add lowercased variations with '_'
        normalized_keys[key.lower().replace('-', '_')] = key

    updated_count = 0
    for filename in os.listdir(l10n_dir):
        # Process only app_*.arb files, excluding app_en.arb
        if not filename.startswith('app_') or not filename.endswith('.arb') or filename == 'app_en.arb':
            continue

        # Extract language code
        arb_lang_code = filename[4:-4]
        
        # Look up the correct key from our normalized_keys map
        found_key = normalized_keys.get(arb_lang_code)
        
        # If no exact match, try the base language
        if found_key is None:
            base_lang_code = arb_lang_code.split('_')[0].split('-')[0]
            if base_lang_code in translations:
                found_key = base_lang_code
            else:
                print(f"No translations found for language code '{arb_lang_code}' or its base language, skipping {filename}...")
                continue

        filepath = os.path.join(l10n_dir, filename)

        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Update the translation keys and remove associated metadata keys
            for key, value in translations[found_key].items():
                data[key] = value
                if f'@{key}' in data:
                    del data[f'@{key}']

            # Write back to file with proper indentation
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
                f.write('\n')  # Add a newline at the end
            
            updated_count += 1
            print(f"Updated {filename} with translations for key '{found_key}'")

        except Exception as e:
            print(f"Error updating {filename}: {str(e)}")

    print(f"\nTotal languages updated: {updated_count}")

if __name__ == '__main__':
    # Check if a file path is provided as a command-line argument
    if len(sys.argv) > 1:
        update_translations(sys.argv[1])
    else:
        update_translations()