# How to Use These Instructions with Claude Opus 4.6 in IntelliJ

## What's Included

You have two self-contained instruction files:

| File | What It Generates | Size |
|------|-------------------|------|
| `INSTRUCTIONS-Generate-Architecture-Diagrams.md` | Single HTML file with Introduction + 9 interactive architecture diagrams (10 pages) | ~1 file |
| `INSTRUCTIONS-Generate-PRD-Documents.md` | PRD.md (Markdown) + PRD-SkillForge.docx (Word document) | ~2 files |

Each instruction file contains the **complete product context** — architecture, features, domain details, technical stack, user journeys — so Claude Opus doesn't need any other reference documents.

---

## Step-by-Step Usage

### Option A: IntelliJ GitHub Copilot Chat with Claude Opus 4.6

1. Open IntelliJ
2. Open the GitHub Copilot Chat panel
3. Make sure **Claude Opus 4.6** is selected as the model
4. Copy the **entire contents** of one instruction file
5. Paste it into the chat as your prompt
6. Claude will generate the requested files

### Option B: Claude Code (CLI) in your project directory

```bash
# Navigate to your project
cd /path/to/skillforge

# For architecture diagrams
claude "$(cat INSTRUCTIONS-Generate-Architecture-Diagrams.md)"

# For PRD documents
claude "$(cat INSTRUCTIONS-Generate-PRD-Documents.md)"
```

### Option C: Attach as file reference in IntelliJ

1. Place the instruction .md files in your project root
2. In Copilot Chat, reference the file:
   ```
   @workspace Read INSTRUCTIONS-Generate-Architecture-Diagrams.md and generate the HTML file as described.
   ```
3. Or:
   ```
   @workspace Read INSTRUCTIONS-Generate-PRD-Documents.md and generate both the PRD.md and the Word document as described.
   ```

---

## Tips for Best Results

**For the Architecture Diagrams:**
- If the output is too long for a single response, ask Claude to generate the Introduction + diagrams 1-5 first, then 6-9
- The HTML file should be self-contained — all CSS inline, only external dependency is Google Fonts
- If diagrams look off, ask Claude to fix specific diagram numbers

**For the PRD Documents:**
- The Markdown PRD should generate in one shot — it's text-only
- The Word document requires Node.js with the `docx` npm package
- If your environment doesn't have `docx` installed: `npm install docx`
- Ask Claude to generate a Node.js script that creates the .docx file, then run it

**For the CIO Brief (bonus):**
- You can also ask: "Using the PRD context, generate a 2-page CIO executive brief. No technical jargon. Focus on: the problem (testing bottleneck), the solution (business users test in plain English), why now (AI makes it feasible), the ask (Phase 1 approval, 8-12 weeks)."

---

## Customization

Both instruction files are editable. Before giving them to Claude, you can:

- **Add your company name** — replace generic references with your org
- **Update the API list** — add or remove services from the Service Registry
- **Change the tech stack** — if your team prefers Python FastAPI over Spring Boot, update the instructions
- **Adjust the phase plan** — change timelines to match your team capacity
- **Add more domain context** — if you have specific vehicle models, offer types, or channel details

---

## File Outputs Expected

### From Architecture Diagrams Instructions:
```
SkillForge-Architecture-Diagrams.html    (single interactive HTML, Introduction + 9 diagrams, ~2200 lines)
```

### From PRD Instructions:
```
PRD.md                                    (Markdown PRD, ~800 lines)
PRD-SkillForge.docx                       (Word document, ~30 pages)
```
