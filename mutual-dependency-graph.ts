#!/usr/bin/env bun

import { readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

type Edge = {
  from: string;
  to: string;
  field: string;
};

const repoRoot = resolve(import.meta.dir);
const defaultInput = resolve(repoRoot, "LeanRustParser/Basic/Mutual.lean");
const args = Bun.argv.slice(2);

function usage(exitCode: number): never {
  console.log("Usage: bun mutual-dependency-graph.ts [--input FILE] [--output FILE] [--edges]");
  console.log("");
  console.log("Writes Graphviz DOT for dependencies inside Mutual.lean.");
  console.log("An edge A -> B labelled f means a field or constructor argument f of A has a type mentioning B.");
  process.exit(exitCode);
}

function option(name: string): string | undefined {
  const index = args.indexOf(name);
  if (index < 0) return undefined;
  const value = args[index + 1];
  if (value === undefined || value.startsWith("--")) usage(1);
  return value;
}

if (args.includes("--help")) usage(0);
const unknownArgs = args.filter((arg, index) =>
  arg.startsWith("--") && !["--input", "--output", "--edges"].includes(arg) ||
  (index > 0 && ["--input", "--output"].includes(args[index - 1]!) === false && !arg.startsWith("--")));
if (unknownArgs.length > 0) usage(1);

const input = resolve(option("--input") ?? defaultInput);
const output = option("--output");
const edgesOnly = args.includes("--edges");

function stripComments(source: string): string {
  // Documentation comments and ordinary block comments cannot contribute type
  // edges. Replacing them with whitespace keeps line-oriented field parsing
  // stable, while avoiding false references from prose.
  return source
    .replace(/\/-[\s\S]*?-\//g, comment => comment.replace(/[^\r\n]/g, " "))
    .replace(/--[^\r\n]*/g, "");
}

function declarationBlocks(source: string): Map<string, string> {
  const starts = [...source.matchAll(/^  (?:structure|inductive) ([A-Za-z_][A-Za-z0-9_]*)\b/gm)];
  const blocks = new Map<string, string>();
  for (let index = 0; index < starts.length; index++) {
    const match = starts[index]!;
    const name = match[1]!;
    const next = starts[index + 1];
    blocks.set(name, source.slice(match.index, next?.index));
  }
  return blocks;
}

function references(typeText: string, names: ReadonlySet<string>): string[] {
  const found = new Set<string>();
  for (const word of typeText.matchAll(/\b[A-Za-z_][A-Za-z0-9_]*\b/g)) {
    if (names.has(word[0]!)) found.add(word[0]!);
  }
  return [...found].sort();
}

function parseEdges(blocks: ReadonlyMap<string, string>): Edge[] {
  const names = new Set(blocks.keys());
  const edges: Edge[] = [];

  for (const [owner, block] of blocks) {
    let constructor: string | undefined;
    for (const rawLine of block.split(/\r?\n/)) {
      const constructorMatch = rawLine.match(/^\s*\|\s*([A-Za-z_][A-Za-z0-9_]*)/);
      if (constructorMatch !== null) constructor = constructorMatch[1]!;

      // Both record fields (`path : Path`) and constructor arguments
      // (`| path (path : Path)`) use named `name : Type` syntax.
      for (const field of rawLine.matchAll(/\b([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^,)]+)/g)) {
        const fieldName = constructor === undefined ? field[1]! : `${constructor}.${field[1]!}`;
        for (const target of references(field[2]!, names)) {
          edges.push({ from: owner, to: target, field: fieldName });
        }
      }
    }
  }

  return edges.sort((left, right) =>
    left.from.localeCompare(right.from) || left.to.localeCompare(right.to) || left.field.localeCompare(right.field));
}

function quote(value: string): string {
  return JSON.stringify(value);
}

function dot(blocks: ReadonlyMap<string, string>, edges: readonly Edge[]): string {
  const lines = [
    "digraph MutualDependencies {",
    "  rankdir=LR;",
    "  graph [label=\"LeanRustParser.Basic.Mutual dependencies\", labelloc=t];",
    "  node [shape=box, fontname=\"monospace\"];",
    "  edge [fontname=\"monospace\"];",
  ];
  for (const name of [...blocks.keys()].sort()) lines.push(`  ${quote(name)};`);
  for (const edge of edges) {
    lines.push(`  ${quote(edge.from)} -> ${quote(edge.to)} [label=${quote(edge.field)}];`);
  }
  lines.push("}");
  return `${lines.join("\n")}\n`;
}

async function main(): Promise<void> {
  const source = stripComments(await readFile(input, "utf8"));
  const blocks = declarationBlocks(source);
  if (blocks.size === 0) throw new Error(`No mutual declarations found in ${input}`);
  const edges = parseEdges(blocks);
  const graph = edgesOnly
    ? `${edges.map(edge => `${edge.from}\t${edge.field}\t${edge.to}`).join("\n")}\n`
    : dot(blocks, edges);

  if (output === undefined) process.stdout.write(graph);
  else {
    await writeFile(resolve(output), graph);
    console.log(`Wrote ${edges.length} dependency edges for ${blocks.size} declarations to ${resolve(output)}`);
  }
}

await main();
