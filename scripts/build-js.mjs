import { build, context } from "esbuild";
import { rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");
const isWatch = process.argv.includes("--watch");

function minifyAssets() {
  const explicit = process.env.ASSET_MINIFY?.trim().toLowerCase();
  if (explicit === "true") return true;
  if (explicit === "false") return false;

  const railsEnv = process.env.RAILS_ENV?.trim().toLowerCase();
  const nodeEnv = process.env.NODE_ENV?.trim().toLowerCase();
  return ["production", "staging"].includes(railsEnv || "") || nodeEnv === "production";
}

const productionLike = minifyAssets();

const buildOptions = {
  absWorkingDir: rootDir,
  entryPoints: {
    public: "app/javascript/public_bundle.js",
    admin: "app/javascript/admin_bundle.js",
  },
  bundle: true,
  format: "iife",
  outdir: "app/assets/builds",
  sourcemap: productionLike ? false : true,
  minify: productionLike,
  target: ["es2018"],
  logLevel: "info",
};

if (isWatch) {
  const watcher = await context(buildOptions);
  await watcher.watch();
} else {
  await build(buildOptions);

  if (productionLike) {
    await Promise.all([
      rm(path.join(rootDir, "app/assets/builds/public.js.map"), { force: true }),
      rm(path.join(rootDir, "app/assets/builds/admin.js.map"), { force: true }),
    ]);
  }
}
