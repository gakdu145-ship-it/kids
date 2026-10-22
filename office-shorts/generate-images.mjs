// Generates a PNG for every ref-images/*.txt prompt via the Gemini API.
// Usage: node generate-images.mjs [name ...]   (no names = all prompts)
import { readdir, readFile, writeFile } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const key = process.env.GEMINI_API_KEY;
if (!key) throw new Error("GEMINI_API_KEY is not set");
const model = process.env.GEMINI_IMAGE_MODEL || "gemini-2.5-flash-image";
const dir = join(dirname(fileURLToPath(import.meta.url)), "ref-images");

const only = process.argv.slice(2);
const names = (await readdir(dir))
  .filter((f) => f.endsWith(".txt"))
  .map((f) => f.slice(0, -4))
  .filter((n) => !only.length || only.includes(n));

for (const name of names) {
  const prompt = (await readFile(join(dir, `${name}.txt`), "utf8")).trim();
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    },
  );
  const body = await res.json();
  if (!res.ok) {
    console.error(`${name}: HTTP ${res.status} ${body.error?.message ?? ""}`);
    continue;
  }
  const image = body.candidates?.[0]?.content?.parts?.find((p) => p.inlineData);
  if (!image) {
    console.error(`${name}: no image returned (${body.candidates?.[0]?.finishReason ?? "unknown"})`);
    continue;
  }
  const out = join(dir, `${name}.png`);
  await writeFile(out, Buffer.from(image.inlineData.data, "base64"));
  console.log(`${name}: saved ${out}`);
}
