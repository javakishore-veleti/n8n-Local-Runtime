#!/usr/bin/env node

/**
 * 03_parse_docx.js
 *
 * Purpose:
 * - Extract plain text from a DOCX file
 *
 * Input (args):
 *   node 03_parse_docx.js <file_path> <category>
 *
 * Output:
 * - JSON to stdout
 */

const fs = require("fs");
const mammoth = require("mammoth");

async function run() {
  const filePath = process.argv[2];
  const category = process.argv[3] || "unknown";

  if (!filePath) {
    throw new Error("Missing file_path argument");
  }

  if (!fs.existsSync(filePath)) {
    throw new Error(`File not found: ${filePath}`);
  }

  const result = await mammoth.extractRawText({ path: filePath });

  const output = {
    file_path: filePath,
    category,
    text: result.value.trim()
  };

  console.log(JSON.stringify(output, null, 2));
}

run().catch(err => {
  console.error(
    JSON.stringify(
      {
        error: "DOCX parse failed",
        message: err.message
      },
      null,
      2
    )
  );
  process.exit(1);
});
