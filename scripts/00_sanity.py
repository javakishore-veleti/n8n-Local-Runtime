#!/usr/bin/env python3

import os
import json
from pathlib import Path

BASE_PATH = os.environ.get(
    "AI_DATA_BASE_PATH",
    "/data/local-ai/my_profile_data"
)

def scan_directory(base_path: Path):
    result = {
        "exists": base_path.exists(),
        "path": str(base_path),
        "categories": {}
    }

    if not base_path.exists():
        return result

    for item in base_path.iterdir():
        if item.is_dir():
            file_count = sum(
                1 for f in item.rglob("*") if f.is_file()
            )
            result["categories"][item.name] = {
                "files": file_count
            }

    return result

if __name__ == "__main__":
    output = scan_directory(Path(BASE_PATH))
    print(json.dumps(output, indent=2))
