import { execSync } from "child_process";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

let gitHash = "dev";
try {
  gitHash = execSync("git rev-parse --short HEAD").toString().trim();
} catch {
  // not in a git repo or git unavailable
}
const buildTime = new Date().toISOString().slice(0, 16).replace("T", " ");

export default defineConfig({
  define: {
    __GIT_HASH__: JSON.stringify(gitHash),
    __BUILD_TIME__: JSON.stringify(buildTime),
  },
  plugins: [react()],
  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true,
    host: "127.0.0.1"
  },
  envPrefix: ["VITE_", "TAURI_"],
  build: {
    target: "es2020",
    minify: !process.env.TAURI_DEBUG ? "esbuild" : false,
    sourcemap: !!process.env.TAURI_DEBUG
  }
});
