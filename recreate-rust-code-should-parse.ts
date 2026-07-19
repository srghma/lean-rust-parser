#!/usr/bin/env bun

import { mkdir, readdir, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, join, relative, resolve } from "node:path";

const repoRoot = resolve(import.meta.dir);
const sourceDir = resolve(process.env.RUST_UI_PARSER_DIR ?? join(repoRoot, "../rust/tests/ui/parser"));
const outputDir = join(repoRoot, "LeanRustParserTests/rust-code");
const leanPrettyprintDir = join(repoRoot, "LeanRustParserTests/rust-code--output-of-lean-prettyprint");
const tempDir = join(repoRoot, ".rust-code-generation-tmp");
const editions = ["2015", "2018", "2021", "2024"] as const;
type Edition = (typeof editions)[number];
const defaultRustc =
  "/nix/store/rmxivbf491cgv8ysclad7ss62l5acqlf-rustc-1.98.0-nightly-2026-06-30-x86_64-unknown-linux-gnu/bin/rustc";
const rustc = process.env.RUSTC ?? defaultRustc;
const defaultRustfmt =
  "/nix/store/598kxgzz2nanp2v9x21hz59m65lrc65k-rustfmt-preview-1.98.0-nightly-2026-06-30-x86_64-unknown-linux-gnu/bin/rustfmt";
const rustfmtForSurvivePeanoLessonQueue =
  "/home/srghma/projects/rustfmt/target/release/rustfmt";
const rustfmt = process.env.RUSTFMT ?? defaultRustfmt;
const args = Bun.argv.slice(2);
const generationConcurrency = 16;

if (args.includes("--help") || args.length > 1) {
  console.log("Usage: bun recreate-rust-code-should-parse.ts [SOURCE_DIR]");
  console.log("Tests every .rs file with Rust editions 2015, 2018, 2021, and 2024.");
  process.exit(args.includes("--help") ? 0 : 1);
}
if (args.length === 1) {
  // The optional argument is intentionally positional: it replaces the default source directory.
  process.env.RUST_UI_PARSER_DIR = args[0];
}

const effectiveSourceDir = resolve(process.env.RUST_UI_PARSER_DIR ?? sourceDir);

async function rustFiles(root: string): Promise<string[]> {
  const result: string[] = [];
  async function visit(dir: string): Promise<void> {
    for (const entry of (await readdir(dir, { withFileTypes: true })).sort((a, b) =>
      a.name.localeCompare(b.name))) {
      const path = join(dir, entry.name);
      if (entry.isDirectory()) await visit(path);
      else if (entry.isFile() && entry.name.endsWith(".rs")) result.push(path);
    }
  }
  await visit(root);
  return result.sort();
}

async function mapConcurrent<T, U>(values: readonly T[], f: (value: T) => Promise<U>): Promise<U[]> {
  const result = new Array<U>(values.length);
  let next = 0;
  async function worker(): Promise<void> {
    while (true) {
      const index = next++;
      if (index >= values.length) return;
      result[index] = await f(values[index]!);
    }
  }
  await Promise.all(Array.from({ length: Math.min(generationConcurrency, values.length) }, worker));
  return result;
}

async function checkWithRustc(file: string, edition: Edition): Promise<boolean> {
  const child = Bun.spawn({
    cmd: [rustc, "-Z", "parse-crate-root-only", "--crate-type", "lib", "--edition", edition, file],
    env: { ...process.env, RUSTC_BOOTSTRAP: "1" },
    stdout: "ignore",
    stderr: "ignore",
  });
  return await child.exited === 0;
}

function rustfmtConfig(): string {
  const config: string[] = [
    // this will make rustfmt not go into ../parser
    //
    // ```rs
    // path = "../parser"]
    // mod foo;
    // ```
    "skip_children=true",
    "tab_spaces=2"
  ];
  return config.join(",");
}

async function formatWithRustfmt(file: string, edition: Edition, relativePath: string): Promise<string> {
  const child = Bun.spawn({
    cmd: [
      relativePath === "survive-peano-lesson-queue.rs" ? rustfmtForSurvivePeanoLessonQueue : rustfmt,
      "--edition",
      edition,
      "--config",
      rustfmtConfig(),
      "--emit",
      "stdout",
      file
    ],
    stdout: "pipe",
    stderr: "ignore",
  });
  const [exitCode, formatted] = await Promise.all([
    child.exited,
    new Response(child.stdout).text(),
  ]);
  if (exitCode !== 0) {
    throw new Error(`rustfmt failed for ${file} in expected edition ${edition}`);
  }
  // `rustfmt --emit stdout` labels each formatted file before its contents.
  // The label is useful for terminal output, but must not become part of a
  // standalone generated Rust fixture.
  const stdoutLabel = `${file}:\n`;
  return formatted.startsWith(stdoutLabel)
    ? formatted.slice(stdoutLabel.length).replace(/^\r?\n/, "")
    : formatted;
}

function rawStringEnd(source: string, start: number): number | undefined {
  let cursor = start;
  if (source[cursor] === "b") cursor++;
  if (source[cursor] !== "r") return undefined;
  cursor++;
  while (source[cursor] === "#") cursor++;
  if (source[cursor] !== '"') return undefined;
  const hashes = cursor - start - (source[start] === "b" ? 2 : 1);
  const closing = `"${"#".repeat(hashes)}`;
  const end = source.indexOf(closing, cursor + 1);
  return end < 0 ? source.length : end + closing.length;
}

function looksLikeCharLiteral(source: string, start: number): boolean {
  let cursor = start + 1;
  if (source[cursor] === "\\") cursor += 2;
  else cursor++;
  return source[cursor] === "'";
}

function removeRustComments(source: string): string {
  const out = source.split("");
  let cursor = 0;
  while (cursor < source.length) {
    const rawEnd = rawStringEnd(source, cursor);
    if (rawEnd !== undefined) {
      cursor = rawEnd;
      continue;
    }
    if (source[cursor] === '"' ||
      (source[cursor] === "'" && looksLikeCharLiteral(source, cursor))) {
      const quote = source[cursor++];
      while (cursor < source.length) {
        if (source[cursor] === "\\") cursor += 2;
        else if (source[cursor] === quote) { cursor++; break; }
        else cursor++;
      }
      continue;
    }
    if (source[cursor] === "/" && source[cursor + 1] === "/") {
      out[cursor++] = " ";
      out[cursor++] = " ";
      while (cursor < source.length && source[cursor] !== "\n") out[cursor++] = " ";
      continue;
    }
    if (source[cursor] === "/" && source[cursor + 1] === "*") {
      const start = cursor;
      let depth = 1;
      cursor += 2;
      while (cursor < source.length && depth > 0) {
        if (source[cursor] === "/" && source[cursor + 1] === "*") { depth++; cursor += 2; }
        else if (source[cursor] === "*" && source[cursor + 1] === "/") { depth--; cursor += 2; }
        else cursor++;
      }
      for (let i = start; i < cursor; i++) {
        if (source[i] !== "\n" && source[i] !== "\r") out[i] = " ";
      }
      continue;
    }
    cursor++;
  }
  return out.join("").replace(/[ \t]+(?=\r?$)/gm, "");
}

function removeEmptyLines(source: string): string {
  return source.split(/\r?\n/).filter(line => line.trim().length > 0).join("\n");
}

function flattenedStem(sourcePath: string): string {
  return sourcePath.replace(/\\/g, "/").replace(/\.rs$/, "").replaceAll("/", "--");
}

function outputName(sourcePath: string, status: string, withoutComments: boolean): string {
  const stem = flattenedStem(sourcePath);
  return `${stem}-${status}${withoutComments ? "-without-comments" : ""}.rs`;
}

async function main(): Promise<void> {
  const files = await rustFiles(effectiveSourceDir);
  if (files.length === 0) throw new Error(`No Rust fixtures found in ${effectiveSourceDir}`);

  const compiler = Bun.spawn({ cmd: [rustc, "--version"], stdout: "ignore", stderr: "ignore" });
  if (await compiler.exited !== 0) throw new Error(`Cannot execute rustc: ${rustc}`);

  await rm(tempDir, { recursive: true, force: true });
  await mkdir(tempDir, { recursive: true });

  console.log(`Testing ${files.length} Rust files from ${effectiveSourceDir}`);
  let completedFiles = 0;
  const runningStages = new Map<string, { relativePath: string; stage: string; startedAt: number }>();
  let nextStageId = 0;
  async function runStage<T>(relativePath: string, stage: string, action: () => Promise<T>): Promise<T> {
    const id = `${nextStageId++}`;
    runningStages.set(id, { relativePath, stage, startedAt: performance.now() });
    try {
      return await action();
    } finally {
      runningStages.delete(id);
    }
  }
  const checkedFiles = await (async () => {
    const progressTimer = setInterval(() => {
      if (runningStages.size === 0) return;
      console.log(`Still working (${completedFiles}/${files.length} complete):`);
      for (const { relativePath, stage, startedAt } of runningStages.values()) {
        const elapsedSeconds = ((performance.now() - startedAt) / 1000).toFixed(1);
        console.log(`  ${relativePath}: ${stage} (${elapsedSeconds}s)`);
      }
    }, 10_000);
    try {
      return await mapConcurrent(files, async (sourcePath) => {
        const source = await readFile(sourcePath, "utf8");
        const withoutComments = removeEmptyLines(removeRustComments(source));
        const relativePath = relative(effectiveSourceDir, sourcePath);
        const withoutCommentsPath = join(tempDir, relativePath);
        await mkdir(dirname(withoutCommentsPath), { recursive: true });
        await writeFile(withoutCommentsPath, withoutComments);
        const statuses = await Promise.all(editions.map(async (edition) => {
          const [originalPasses, withoutCommentsPasses] = await Promise.all([
            runStage(relativePath, `rustc source, edition ${edition}`, () => checkWithRustc(sourcePath, edition)),
            runStage(relativePath, `rustc comment-free source, edition ${edition}`, () => checkWithRustc(withoutCommentsPath, edition)),
          ]);
          return originalPasses && withoutCommentsPasses;
        }));
        const status = statuses.map(pass => pass ? "t" : "f").join("");
        const formattingEdition = editions.findLast((_, index) => statuses[index]);
        const formattedWithoutComments = formattingEdition === undefined
          ? undefined
          : await runStage(relativePath, `rustfmt, edition ${formattingEdition}, config ${rustfmtConfig(relativePath)}`, () =>
            formatWithRustfmt(withoutCommentsPath, formattingEdition, relativePath));
        completedFiles++;
        if (completedFiles % 25 === 0 || completedFiles === files.length) {
          console.log(`Processed ${completedFiles}/${files.length}: ${relativePath}`);
        }
        return { source, withoutComments: formattedWithoutComments, relativePath, status };
      });
    } finally {
      clearInterval(progressTimer);
    }
  })();

  await rm(outputDir, { recursive: true, force: true });
  await rm(leanPrettyprintDir, { recursive: true, force: true });
  await mkdir(outputDir, { recursive: true });
  const flattenedSources = new Map<string, string>();
  await Promise.all(checkedFiles.map(async ({ source, withoutComments, relativePath, status }) => {
    const stem = flattenedStem(relativePath);
    const previous = flattenedSources.get(stem);
    if (previous !== undefined && previous !== relativePath) {
      throw new Error(
        `there was a clash during writing file ${relativePath} as ${stem}.rs bc there is already present file ${previous}. ` +
        "Try to choose different replacement separator for dirs",
      );
    }
    flattenedSources.set(stem, relativePath);
    const name = outputName(relativePath, status, false);
    await writeFile(join(outputDir, name), source);
    if (withoutComments !== undefined) {
      const withoutCommentsName = name.replace(/\.rs$/, "-without-comments.rs");
      await writeFile(join(outputDir, withoutCommentsName), withoutComments);
    }
  }));

  await rm(tempDir, { recursive: true, force: true });
  const companionCount = checkedFiles.filter((file) => file.withoutComments !== undefined).length;
  console.log(`Wrote ${files.length + companionCount} files to ${outputDir}.`);
}

await main();
