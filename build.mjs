// Builds every format of the moonbase Skill from ONE source, the moonbase/
// folder next to this file
// (SKILL.md + references/), so no copy can drift from another:
//   - moonbase-guide.md: SKILL.md then every reference, in one file, for any
//     chat that takes a single file;
//   - the adapters in adapters.json (AGENTS.md, Cursor rule, CLAUDE.md
//     snippet, Copilot instructions, ChatGPT and Gemini packs). Each is the
//     same text with a short, tool-specific header; the chat packs use the
//     "core" (the parts of SKILL.md between <!-- core --> markers) as their
//     short instructions, with the guide as their knowledge file.
// Vendor-specific wording lives only here, in each adapter's header.
// `node build.mjs` prints the guide; `node build.mjs kit <dir>` writes every
// format into <dir>/moonbase-skill-kit/.
import { readFileSync, readdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = path.join(HERE, "moonbase");

/** The ChatGPT GPT builder's Instructions field holds at most 8,000 characters. */
export const GPT_INSTRUCTIONS_MAX = 8000;
/**
 * Gemini Gems: Google publishes no limit; the only figure found (a secondary
 * source, 2026-10) is about 4,000 characters, so the Gem pack stays under it.
 */
export const GEM_INSTRUCTIONS_MAX = 4000;

const VERSION_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/**
 * The skill's version and date, parsed from SKILL.md's "## Skill version" line
 * (`**moonbase skill — revision r16, 2026-11-01.**`). This is the ONE source of
 * truth: the download filenames and the /skill page label all derive from it,
 * so bumping the revision in SKILL.md updates them with no second place to edit.
 * The build writes the parsed result to version.json, which the moonbase.cloud
 * /skill page and downloads read.
 */
export function skillVersion(dir = SKILL_DIR) {
  const skillMd = readFileSync(path.join(dir, "SKILL.md"), "utf8");
  // Only the "## Skill version" section is authoritative, so an earlier prose
  // mention like "revision r2 did X" elsewhere in the file can't win silently.
  const section = skillMd.split(/^## /m).find((s) => s.startsWith("Skill version"));
  if (!section) throw new Error('SKILL.md has no "## Skill version" section');
  const m = section.match(/revision\s+(r\d+),\s*(\d{4})-(\d{2})-(\d{2})/);
  if (!m) throw new Error('SKILL.md\'s "## Skill version" section has no "revision rN, YYYY-MM-DD" line');
  const [, revision, y, mo, d] = m;
  const month = Number(mo);
  const day = Number(d);
  if (month < 1 || month > 12 || day < 1 || day > 31) throw new Error(`SKILL.md version date is out of range: ${y}-${mo}-${d}`);
  return {
    revision,
    date: `${y}-${mo}-${d}`,
    label: `Version ${revision} · ${VERSION_MONTHS[month - 1]} ${day}, ${y}`,
    skillFilename: `moonbase-skill-${revision}.skill`,
    guideFilename: `moonbase-guide-${revision}.md`,
    kitFilename: `moonbase-skill-kit-${revision}.zip`,
  };
}

/** Expand {skillFile}/{guideFile} placeholders in adapters.json "use" text to the versioned download names. */
export function expandUse(use, v) {
  return use.replace(/\{skillFile\}/g, v.skillFilename).replace(/\{guideFile\}/g, v.guideFilename);
}

const GUIDE_HEADER = `<!--
  The moonbase Skill, single-file version. Generated from the moonbase Skill
  folder; all formats: https://moonbase.cloud/skill
-->
`;

/** Reference files in the order SKILL.md's table first mentions them, then any it doesn't. */
export function referenceOrder(skillMd, files) {
  const seen = [...skillMd.matchAll(/references\/([a-z0-9-]+\.md)/g)].map((m) => m[1]);
  const ordered = [...new Set(seen)].filter((f) => files.includes(f));
  return [...ordered, ...files.filter((f) => !ordered.includes(f)).sort()];
}

/** Every Markdown heading one level down, leaving fenced code (shell comments) alone. */
function demote(text) {
  let fenced = false;
  return text
    .split("\n")
    .map((line) => {
      if (line.startsWith("```")) fenced = !fenced;
      return !fenced && /^#+ /.test(line) ? "#" + line : line;
    })
    .join("\n");
}

function readSkill(dir) {
  const skillMd = readFileSync(path.join(dir, "SKILL.md"), "utf8");
  const files = readdirSync(path.join(dir, "references")).filter((f) => f.endsWith(".md"));
  const refs = referenceOrder(skillMd, files).map((file) => {
    const text = readFileSync(path.join(dir, "references", file), "utf8");
    return { file, title: text.match(/^# (.+)$/m)?.[1] ?? file, text };
  });
  const [, frontmatter, body] = skillMd.match(/^(---\n[\s\S]*?\n---\n)([\s\S]*)$/) ?? [null, "", skillMd];
  return { frontmatter, body, refs, titles: Object.fromEntries(refs.map((r) => [r.file, r.title])) };
}

/** "references/x.md" / "x.md" pointers → section names, since a single file has no folders. */
function relinker(titles, where) {
  return (text) =>
    text
      .replace(/`references\/([a-z0-9-]+\.md)`/g, (m, f) => (titles[f] ? `the section "${titles[f]}"${where}` : m))
      .replace(/`([a-z0-9-]+\.md)`/g, (m, f) => (titles[f] ? `the section "${titles[f]}"` : m));
}

const stripComments = (text) => text.replace(/<!--[\s\S]*?-->\n?/g, "");

/** The guide's body without frontmatter: SKILL.md, then each reference one level down. */
function guideBody(dir) {
  const { body, refs, titles } = readSkill(dir);
  const relink = relinker(titles, " below");
  const parts = [stripComments(relink(body)).trimEnd()];
  for (const r of refs) parts.push(demote(relink(r.text)).trimEnd());
  return parts.join("\n\n---\n\n") + "\n";
}

export function buildGuide(dir = SKILL_DIR) {
  return readSkill(dir).frontmatter + GUIDE_HEADER + "\n" + guideBody(dir);
}

/** SKILL.md's core blocks: who you are, what you can do, how to teach, the words, the rules. */
export function buildCore(dir = SKILL_DIR) {
  const { body, titles } = readSkill(dir);
  const blocks = [...body.matchAll(/<!-- core -->\n([\s\S]*?)<!-- \/core -->/g)].map((m) => m[1].trim());
  if (!blocks.length) throw new Error("SKILL.md has no <!-- core --> blocks");
  return relinker(titles, " of the moonbase guide")(blocks.join("\n\n")) + "\n";
}

/** Only the named "## " sections of the core ("" = the text before the first heading). */
function coreSections(core, headings) {
  const parts = core.split(/^(?=## )/m);
  return (
    parts
      .filter((p) => headings.includes(p.startsWith("## ") ? p.slice(3, p.indexOf("\n")) : ""))
      .map((p) => p.trim())
      .join("\n\n") + "\n"
  );
}

const CHAT_KNOWLEDGE = (where) => `## Your knowledge file

${where} holds the moonbase guide. Read the relevant section before answering.
If the answer isn't there, point to https://moonbase.cloud/docs.

Once their account is ready, use the moonbase connector if your chat has it
(create_upload for a project with images or over about 100 KB). Otherwise,
guide them through the browser upload.
`;

/** The one line that sends an always-loaded adapter to the full guide when it needs a detail. */
export const FULL_GUIDE_URL = "https://moonbase.cloud/api/skill";
// The always-loaded files (AGENTS.md, CLAUDE.md, Copilot) have little room
// under their limit, and the core instructions aren't where the bytes go: this
// pointer and the header comment are. Both are as short as they can be while
// saying the same thing.
const FULL_GUIDE_POINTER = `## Full guide

Every step, button, error code and rule: \`moonbase-guide.md\` if this project
has it, else ${FULL_GUIDE_URL} (plain text). Read the section you need; don't
answer from memory.
`;

/** One-line header comment for a generated adapter: what it is, and where every format lives. */
const AGENT_HEADER = (line) => `<!-- ${line} · all formats: https://moonbase.cloud/skill -->

`;

/** Every file in the moonbase Skill kit, by its path inside the kit. */
export function buildKit(dir = SKILL_DIR) {
  const guide = buildGuide(dir);
  const body = guideBody(dir);
  const core = buildCore(dir);
  const description = readSkill(dir).frontmatter.match(/description: >-\n([\s\S]*?)\n---/)?.[1].replace(/\s+/g, " ").trim() ?? "";
  // Files a tool loads into EVERY session (AGENTS.md, CLAUDE.md, Copilot) get
  // only the short core plus a pointer to the full guide, which coding agents
  // fetch when they need a detail -- never the whole guide. The Cursor rule is agent-requested (alwaysApply:
  // false), loaded only when relevant, so it carries the whole guide.
  const kit = {
    "moonbase-guide.md": guide,
    "AGENTS.md":
      AGENT_HEADER("moonbase instructions for AI coding agents (AGENTS.md): put in the project root, or add to yours") +
      core +
      "\n" +
      FULL_GUIDE_POINTER,
    ".cursor/rules/moonbase.mdc":
      `---\ndescription: ${description.replace(/\n/g, " ")}\nglobs:\nalwaysApply: false\n---\n\n` +
      AGENT_HEADER("moonbase Cursor rule: save as .cursor/rules/moonbase.mdc (the full guide, loaded when relevant)") +
      body,
    "CLAUDE.md": `## moonbase\n\n` + `This project is hosted on moonbase (moonbase.cloud). When the user asks to\n` + `deploy, host, publish or share it, or asks anything about moonbase, follow\n` + `these instructions (or the moonbase skill, if it's installed).\n\n` + core + "\n" + FULL_GUIDE_POINTER,
    ".github/copilot-instructions.md":
      AGENT_HEADER("moonbase GitHub Copilot instructions: save as .github/copilot-instructions.md, or add to yours") + core + "\n" + FULL_GUIDE_POINTER,
    "chatgpt/instructions.txt": core + "\n" + CHAT_KNOWLEDGE("The file in this GPT's Knowledge"),
    "chatgpt/moonbase-guide.md": guide,
    // A Gem gets the account-first opening, how to teach and the rules.
    // The complete path for each tool is in its knowledge file.
    "gemini/gem-instructions.md":
      coreSections(core, ["", "How to teach (read this first)", "Rules you never break"]) + "\n" + CHAT_KNOWLEDGE("The knowledge file added to this Gem"),
    "gemini/moonbase-guide.md": guide,
  };
  const { adapters } = JSON.parse(readFileSync(path.join(HERE, "adapters.json"), "utf8"));
  const v = skillVersion(dir);
  kit["README.md"] =
    "# The moonbase Skill kit\n\nThe same moonbase guide in every format. Pick the one for your tool.\n\n" +
    "| Tool | File | How to use it |\n|---|---|---|\n" +
    adapters.map((a) => `| ${a.tools} | \`${a.kitPath}\` | ${expandUse(a.use, v)} |`).join("\n") +
    "\n\nAll formats, always current: https://moonbase.cloud/skill\n";
  return kit;
}

/** Kit files also served one by one from public/: kit path → public path. */
export function servedFiles() {
  const { adapters } = JSON.parse(readFileSync(path.join(HERE, "adapters.json"), "utf8"));
  return Object.fromEntries(adapters.filter((a) => a.download.startsWith("/skill/files/")).map((a) => [a.kitPath, "public" + a.download]));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const { mkdirSync, writeFileSync } = await import("node:fs");
  const [cmd, out] = process.argv.slice(2);
  const kit = buildKit();
  if (cmd === "kit") {
    // The kit tree for zipping: out/moonbase-skill-kit/<kit path>, plus the skill folder.
    for (const [rel, text] of Object.entries(kit)) {
      const file = path.join(out, "moonbase-skill-kit", rel);
      mkdirSync(path.dirname(file), { recursive: true });
      writeFileSync(file, text);
    }
  } else if (cmd === "public") {
    const root = path.join(HERE, "..");
    const write = (rel, text) => {
      mkdirSync(path.dirname(path.join(root, rel)), { recursive: true });
      writeFileSync(path.join(root, rel), text);
    };
    // The downloadable guide lives OUTSIDE public/ so it is never served as a
    // raw static file; only moonbase's versioned, counted download serves it.
    mkdirSync(path.join(HERE, "dist"), { recursive: true });
    writeFileSync(path.join(HERE, "dist", "moonbase-guide.md"), kit["moonbase-guide.md"]);
    // version.json stays under public/: it is metadata, not a download.
    write("public/skill/version.json", JSON.stringify(skillVersion(), null, 2) + "\n");
    for (const [kitPath, publicPath] of Object.entries(servedFiles())) write(publicPath, kit[kitPath]);
  } else {
    process.stdout.write(kit["moonbase-guide.md"]);
  }
}
