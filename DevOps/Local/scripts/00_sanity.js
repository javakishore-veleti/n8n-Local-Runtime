#!/usr/bin/env node

/**
 * 00_sanity.js
 *
 * Purpose:
 * - Verify that the profile data base directory exists
 * - List top-level category folders
 * - Count direct (non-hidden) files inside each category
 *
 * Rules:
 * - Skip hidden files/folders (e.g. .DS_Store)
 * - Skip "do-not-consider" directories entirely
 * - Do NOT recurse into subfolders
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
const BASE_PATH = "/data/my_profile_data";

/**
 * Count only direct, visible files in a directory
 */
function countDirectFiles(dirPath) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });

  return entries.filter(entry =>
    entry.isFile() &&
    !entry.name.startsWith(".") // skips .DS_Store and all hidden files
  ).length;
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
    // Skip non-directories
    if (!entry.isDirectory()) continue;

    // Skip hidden folders
    if (entry.name.startsWith(".")) continue;

    // Skip do-not-consider folder
    if (entry.name === "do-not-consider") continue;

    const categoryPath = path.join(basePath, entry.name);

    const fileCount = countDirectFiles(categoryPath);

    result.categories[entry.name] = {
      path: categoryPath,
      file_count: fileCount
    };
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
