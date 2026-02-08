#!/usr/bin/env node

/**
 * 02_discover_files.js
 *
 * Purpose:
 * - Recursively discover profile data files
 * - Skip `do-not-consider` folders
 * - Skip system files like `.DS_Store`
 *
 * Output:
 * - One absolute file path per line (stdout)
 *
 * Safe:
 * - Read-only
 */

const fs = require("fs");
const path = require("path");

// Base directory mounted into n8n + runner container
const BASE_PATH = "/data/my_profile_data";

// Folders / files to skip
const SKIP_DIRS = new Set(["do-not-consider"]);
const SKIP_FILES = new Set([".DS_Store"]);

/**
 * Recursively walk directory and collect files
 */
function walk(dir, results = []) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    if (SKIP_FILES.has(entry.name)) continue;

    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      walk(fullPath, results);
    } else if (entry.isFile()) {
      results.push(fullPath);
    }
  }

  return results;
}

/**
 * Main
 */
try {
  if (!fs.existsSync(BASE_PATH)) {
    // No output → downstream nodes can handle "no files"
    process.exit(0);
  }

  const files = walk(BASE_PATH);

  for (const file of files) {
    console.log(file);
  }
} catch (err) {
  console.error(err.message);
  process.exit(1);
}
