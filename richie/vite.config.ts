import { defineConfig } from "vite";

export default defineConfig({
  logLevel: "warn",
  build: {
    outDir: "dist/public",
    emptyOutDir: true,
    lib: { entry: "src/client.ts", formats: ["es"], fileName: "client" }
  }
});
