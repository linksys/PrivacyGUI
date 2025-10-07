import json
import os
import sys
from collections import OrderedDict

def update_translations(translations_file_path=None):
    """
    Updates translation files (*.arb) in the 'lib/l10n' directory.
    For 'app_en.arb', it only sorts the keys without updating strings.
    For other languages, it updates the translations from a JSON file.

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

    # Construct the path to the 'lib/l10n' directory
    l10n_dir = os.path.join(os.path.dirname(script_dir), 'lib', 'l10n')

    # Ensure the l10n_dir exists
    if not os.path.isdir(l10n_dir):
        print(f"Error: Directory '{l10n_dir}' not found. Please ensure the script is in the correct location relative to your 'lib/l10n' folder.")
        return

    # Load translations only if we are not just sorting app_en.arb
    translations = {}
    try:
        with open(translations_file, 'r', encoding='utf-8') as f:
            translations = json.load(f)
    except FileNotFoundError:
        print(f"Info: The translations file '{translations_file}' was not found. Proceeding with sorting only.")
    except json.JSONDecodeError:
        print(f"Error: The translations file '{translations_file}' is not a valid JSON file. Cannot perform updates.")
        return

    # Pre-process translations dictionary for easier lookup
    normalized_keys = {}
    for key in translations.keys():
        normalized_keys[key] = key
        normalized_keys[key.lower()] = key
        normalized_keys[key.replace('-', '_')] = key
        normalized_keys[key.lower().replace('-', '_')] = key

    updated_count = 0
    sorted_count = 0
    for filename in os.listdir(l10n_dir):
        if not filename.startswith('app_') or not filename.endswith('.arb'):
            continue

        filepath = os.path.join(l10n_dir, filename)

        if filename == 'app_en.arb':
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    data = json.load(f, object_pairs_hook=OrderedDict)

                # Separate main keys and metadata keys
                main_keys = [k for k in data.keys() if not k.startswith('@')]
                meta_keys = {k: data[k] for k in data.keys() if k.startswith('@')}
                
                # Sort main keys alphabetically
                main_keys.sort()

                # Create a new ordered dictionary with the desired order
                sorted_data = OrderedDict()
                for key in main_keys:
                    sorted_data[key] = data[key]
                    meta_key = f'@{key}'
                    if meta_key in meta_keys:
                        sorted_data[meta_key] = meta_keys[meta_key]

                # Write back to the file
                with open(filepath, 'w', encoding='utf-8') as f:
                    json.dump(sorted_data, f, ensure_ascii=False, indent=2)
                    f.write('\n')
                
                sorted_count += 1
                print(f"Sorted keys in {filename}")

            except Exception as e:
                print(f"Error sorting {filename}: {str(e)}")
        else:
            # Logic for other language files
            if not translations:
                continue # Skip if translations file wasn't loaded

            arb_lang_code = filename[4:-4]
            found_key = normalized_keys.get(arb_lang_code)
            
            if found_key is None:
                base_lang_code = arb_lang_code.split('_')[0].split('-')[0]
                found_key = normalized_keys.get(base_lang_code)

            if found_key is None:
                print(f"No translations found for language code '{arb_lang_code}', skipping {filename}...")
                continue

            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    data = json.load(f)

                # Update translation keys and remove associated metadata
                for key, value in translations[found_key].items():
                    data[key] = value
                    if f'@{key}' in data:
                        del data[f'@{key}']

                # Write back to file, sorting keys alphabetically
                with open(filepath, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
                    f.write('\n')
                
                updated_count += 1
                print(f"Updated {filename} with translations for key '{found_key}'")

            except Exception as e:
                print(f"Error updating {filename}: {str(e)}")

    print(f"\nTotal languages sorted: {sorted_count}")
    print(f"Total languages updated: {updated_count}")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        update_translations(sys.argv[1])
    else:
        update_translations()
