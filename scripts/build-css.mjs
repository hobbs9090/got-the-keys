import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as sass from "sass";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");
const isWatch = process.argv.includes("--watch");
const targets = [
  ["app/assets/stylesheets/public_bundle.scss", "app/assets/builds/public.css"],
  ["app/assets/stylesheets/admin_bundle.scss", "app/assets/builds/admin.css"],
];

function minifyAssets() {
  const explicit = process.env.ASSET_MINIFY?.trim().toLowerCase();
  if (explicit === "true") return true;
  if (explicit === "false") return false;

  const railsEnv = process.env.RAILS_ENV?.trim().toLowerCase();
  const nodeEnv = process.env.NODE_ENV?.trim().toLowerCase();
  return ["production", "staging"].includes(railsEnv || "") || nodeEnv === "production";
}

function sassCliPath() {
  const localPath = path.join(rootDir, "node_modules", ".bin", process.platform === "win32" ? "sass.cmd" : "sass");
  return existsSync(localPath) ? localPath : "sass";
}

async function buildOnce() {
  const style = minifyAssets() ? "compressed" : "expanded";
  const sourceMap = !minifyAssets();

  for (const [source, destination] of targets) {
    const destinationPath = path.join(rootDir, destination);
    await mkdir(path.dirname(destinationPath), { recursive: true });

    const result = sass.compile(path.join(rootDir, source), {
      loadPaths: [path.join(rootDir, "node_modules")],
      style,
      sourceMap,
      sourceMapIncludeSources: sourceMap,
    });

    const cssOutput = sourceMap
      ? `${result.css}\n/*# sourceMappingURL=${path.basename(destinationPath)}.map */\n`
      : result.css;

    await writeFile(destinationPath, cssOutput);

    if (sourceMap && result.sourceMap) {
      await writeFile(`${destinationPath}.map`, JSON.stringify(result.sourceMap));
    } else {
      await rm(`${destinationPath}.map`, { force: true });
    }
  }
}

function watch() {
  const args = [
    "--no-source-map",
    "--silence-deprecation=import,global-builtin,color-functions,if-function",
    "--load-path=node_modules",
    "--watch",
    ...targets.map(([source, destination]) => `${source}:${destination}`),
  ];

  const child = spawn(sassCliPath(), args, {
    cwd: rootDir,
    stdio: "inherit",
    env: process.env,
  });

  child.on("exit", (code, signal) => {
    if (signal) {
      process.kill(process.pid, signal);
      return;
    }

    process.exit(code ?? 0);
  });
}

if (isWatch) {
  watch();
} else {
  await buildOnce();
}
