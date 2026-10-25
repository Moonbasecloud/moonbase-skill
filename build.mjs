// Builds every format of the moonbase Skill from ONE source, skill/moonbase/
// (SKILL.md + references/), so no copy can drift from another:
//   - moonbase-guide.md: SKILL.md then every reference, in one file, for any
//     chat that takes a single file;
//   - the adapters in skill/adapters.json (AGENTS.md, Cursor rule, CLAUDE.md
//     snippet, Copilot instructions, ChatGPT and Gemini packs). Each is the
//     same text with a short, tool-specific header; the chat packs use the
//     "core" (the parts of SKILL.md between <!-- core --> markers) as their
//     short instructions, with the guide as their knowledge file.
// Vendor-specific wording lives only here, in each adapter's header.
// Run by skill/package.sh; the drift test rebuilds and compares.
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

const GUIDE_HEADER = `<!--
  The moonbase Skill, single-file version. Generated from skill/moonbase/ in
  the moonbase repo; all formats: https://moonbase.cloud/skill
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

${where} holds the whole moonbase guide (moonbase-guide.md): every step,
button name, error code and limit rule. Look up the matching section before
you answer any moonbase question, and follow its steps. If the answer isn't
in it, say you're not sure and point to https://moonbase.cloud/docs.

You can only chat here: guide the user click by click through moonbase in
their browser and help them prepare the ZIP. You can't deploy for them.
`;

/** The one line that sends an always-loaded adapter to the full guide when it needs a detail. */
export const FULL_GUIDE_URL = "https://moonbase.cloud/api/skill";
const FULL_GUIDE_POINTER = `## The full guide (read it when you need a step or a detail)

These are the short instructions. Every step, button name, error code and
rule is in the full moonbase guide: open \`moonbase-guide.md\` if this project
has it, otherwise download ${FULL_GUIDE_URL} (it's plain text) and read the
section you need. Don't answer from memory when the guide can tell you.
`;

const AGENT_HEADER = (lines) => `<!--
${lines.map((l) => (l ? "  " + l : "")).join("\n")}
  Generated from the moonbase Skill (skill/moonbase/); all formats:
  https://moonbase.cloud/skill
-->

`;

/** Every file in the moonbase Skill kit, by its path inside the kit. */
export function buildKit(dir = SKILL_DIR) {
  const guide = buildGuide(dir);
  const body = guideBody(dir);
  const core = buildCore(dir);
  const description = readSkill(dir).frontmatter.match(/description: >-\n([\s\S]*?)\n---/)?.[1].replace(/\s+/g, " ").trim() ?? "";
  // Files a tool loads into EVERY session (AGENTS.md, CLAUDE.md, Copilot) get
  // only the short core plus a pointer to the full guide, which coding agents
  // fetch when they need a detail -- never the whole guide (Argus N1, Luna's
  // final ruling on #941). The Cursor rule is agent-requested (alwaysApply:
  // false), loaded only when relevant, so it carries the whole guide.
  const shortNote = [
    `These are the short moonbase instructions (about ${Math.round((core.length + FULL_GUIDE_POINTER.length) / 1024)} KB), loaded every`,
    "session; they point to the full guide, which you read when you need it.",
  ];
  const cursorNote = [
    `This rule is the full moonbase guide (about ${Math.round(body.length / 1024)} KB). Cursor loads it only`,
    "when the conversation is about hosting, deploying or moonbase.",
  ];
  const kit = {
    "moonbase-guide.md": guide,
    "AGENTS.md":
      AGENT_HEADER([
        "moonbase instructions for AI coding agents (the AGENTS.md standard).",
        "Put this file in the project's root folder, or add its text to the",
        "AGENTS.md you already have.",
        "",
        ...shortNote,
      ]) +
      core +
      "\n" +
      FULL_GUIDE_POINTER,
    ".cursor/rules/moonbase.mdc":
      `---\ndescription: ${description.replace(/\n/g, " ")}\nglobs:\nalwaysApply: false\n---\n\n` +
      AGENT_HEADER(["Cursor rule: save as .cursor/rules/moonbase.mdc.", "", ...cursorNote]) +
      body,
    "CLAUDE.md": `## moonbase\n\n` + `This project is hosted on moonbase (moonbase.cloud). When the user asks to\n` + `deploy, host, publish or share it, or asks anything about moonbase, follow\n` + `these instructions (or the moonbase skill, if it's installed).\n\n` + core + "\n" + FULL_GUIDE_POINTER,
    ".github/copilot-instructions.md":
      AGENT_HEADER(["GitHub Copilot repository instructions: save as", ".github/copilot-instructions.md, or add this text to yours.", "", ...shortNote]) + core + "\n" + FULL_GUIDE_POINTER,
    "chatgpt/instructions.txt": core + "\n" + CHAT_KNOWLEDGE("The file in this GPT's Knowledge"),
    "chatgpt/moonbase-guide.md": guide,
    // A Gem is chat-only: the short opening, how to teach and the rules; the rest is in its knowledge file.
    "gemini/gem-instructions.md":
      coreSections(core, ["", "How to teach (read this first)", "Rules you never break"]) + "\n" + CHAT_KNOWLEDGE("The knowledge file added to this Gem"),
    "gemini/moonbase-guide.md": guide,
  };
  const { adapters } = JSON.parse(readFileSync(path.join(HERE, "adapters.json"), "utf8"));
  kit["README.md"] =
    "# The moonbase Skill kit\n\nThe same moonbase guide in every format. Pick the one for your tool.\n\n" +
    "| Tool | File | How to use it |\n|---|---|---|\n" +
    adapters.map((a) => `| ${a.tools} | \`${a.kitPath}\` | ${a.use} |`).join("\n") +
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
    write("public/skill/moonbase-guide.md", kit["moonbase-guide.md"]);
    write("public/skill/build-for-moonbase/SKILL.md", kit["moonbase-guide.md"]);
    for (const [kitPath, publicPath] of Object.entries(servedFiles())) write(publicPath, kit[kitPath]);
  } else {
    process.stdout.write(kit["moonbase-guide.md"]);
  }
}
