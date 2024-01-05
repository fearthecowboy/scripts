// example deno script
// can be run with `deno run -A https://raw.githubusercontent.com/fearthecowboy/scripts/main/example.ts`
import { readFile, readdir } from 'node:fs/promises';

console.log('hi')
const results = await readdir(".");
console.log(results);