#!/usr/bin/env node
import { request } from "node:http";
import { realpath } from "node:fs/promises";
import { spawn } from "node:child_process";

const socket = process.env.RICHIE_CONTROL_SOCKET ?? "/run/richie/control.sock";
function control(path: string, payload?: unknown): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const requestHandle = request({ socketPath: socket, path, method: payload ? "POST" : "GET", headers: payload ? { "content-type": "application/json" } : undefined }, (response) => { let output = ""; response.on("data", (chunk) => output += chunk); response.on("end", () => response.statusCode && response.statusCode < 300 ? resolve(JSON.parse(output)) : reject(new Error(JSON.parse(output).error ?? "Richie service error"))); });
    requestHandle.on("error", () => reject(new Error("Richie service is unavailable. Start it with: sudo systemctl start richie")));
    if (payload) requestHandle.end(JSON.stringify(payload)); else requestHandle.end();
  });
}
async function main(): Promise<void> {
  const [command, input] = process.argv.slice(2);
  if (command === "status") { console.log(JSON.stringify(await control("/status"))); return; }
  if (command !== "review" || !input) throw new Error("Usage: richie review path/to/draft-vNN.md");
  const sourcePath = await realpath(input); const result = await control("/sessions", { sourcePath }) as { url: string };
  spawn("xdg-open", [result.url], { detached: true, stdio: "ignore" }).unref(); console.log(result.url);
}
main().catch((error: Error) => { console.error(error.message); process.exitCode = 1; });
