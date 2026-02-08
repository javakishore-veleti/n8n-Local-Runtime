#!/usr/bin/env node

/**
 * 00_sanity.js
 *
 * Purpose:
 * - Verify that the profile data base directory exists
 * - List top-level category folders
 * - Count files recursively under each category
 *
 * Output:
 * - JSON (printed to stdout)
 *
 * Safe:
 * - Read-only
 * - No mutations
 */

const fs = require("fs");
const path = require("path");

// Base path mounted into n8n via docker-compose
// const BASE_PATH =
//  process.env.MY_PROFILE_DATA_HOST_PATH || "/data/my_profile_data";

const BASE_PATH = "/data/my_profile_data";

/**
 * Recursively count files in a directory
 */
function countFilesRecursive(dirPath) {
  let count = 0;

  const entries = fs.readdirSync(dirPath, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);

    if (entry.isFile()) {
      count++;
    } else if (entry.isDirectory()) {
      count += countFilesRecursive(fullPath);
    }
  }

  return count;
}

/**
 * Main sanity logic
 */
function runSanityCheck(basePath) {
  const result = {
    base_path: basePath,
    exists: false,
    categories: {}
  };

  if (!fs.existsSync(basePath)) {
    return result;
  }

  result.exists = true;

  const topLevelEntries = fs.readdirSync(basePath, { withFileTypes: true });

  for (const entry of topLevelEntries) {
    if (entry.isDirectory()) {
      const categoryPath = path.join(basePath, entry.name);
      const fileCount = countFilesRecursive(categoryPath);

      result.categories[entry.name] = {
        path: categoryPath,
        file_count: fileCount
      };
    }
  }

  return result;
}

// Execute
try {
  const output = runSanityCheck(BASE_PATH);
  console.log(JSON.stringify(output, null, 2));
} catch (err) {
  console.error(
    JSON.stringify(
      {
        error: "Sanity check failed",
        message: err.message,
        stack: err.stack
      },
      null,
      2
    )
  );
  process.exit(1);
}
