import os
import json

BASE_PATH = "/data/my_profile_data"

result = {
    "base_path": BASE_PATH,
    "exists": False,
    "folders": {}
}

if os.path.isdir(BASE_PATH):
    result["exists"] = True

    for entry in sorted(os.listdir(BASE_PATH)):
        folder_path = os.path.join(BASE_PATH, entry)
        if os.path.isdir(folder_path):
            file_count = 0
            for _, _, files in os.walk(folder_path):
                file_count += len(files)

            result["folders"][entry] = {
                "path": folder_path,
                "file_count": file_count
            }

print(json.dumps(result, indent=2))
