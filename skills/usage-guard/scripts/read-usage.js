// Run with mcp__claude-in-chrome__javascript_tool on https://claude.ai/new#settings/usage.
// Reads the "Current session" block in English or Turkish and returns
// {percent, resets, relative, language} as JSON, or null when the block is not found.
// Reload the tab first (navigate to the same URL) so the numbers are fresh.
await new Promise(r => setTimeout(r, 2500));
const text = (document.querySelector('[role=dialog]') || document.body).innerText;
const layouts = [
  // English: "Current session / Resets at 5:40 AM / 62% used"
  { language: 'en', block: /Current session\s*(Resets[^\n]*)\s*(\d+)\s*%\s*used/i, prefix: /^Resets\s*(at|in)?\s*/i, relative: /^Resets\s+in/i },
  // Turkish: "Mevcut oturum / Sıfırlanma zamanı: 17:10 / %10 kullanılmış"
  { language: 'tr', block: /Mevcut oturum\s*(Sıfırlanma[^\n]*)\s*%\s*(\d+)\s*kullanılmış/i, prefix: /^Sıfırlanma(\s+zamanı)?\s*:?\s*/i, relative: /\b(sa|saat|dk|dakika)\b/i },
];
let result = null;
for (const layout of layouts) {
  const match = text.match(layout.block);
  if (!match) continue;
  const resets = match[1].replace(layout.prefix, '').trim();
  result = JSON.stringify({
    percent: Number(match[2]),
    resets,
    relative: layout.relative.test(layout.language === 'en' ? match[1] : resets) && !/\d{1,2}[:.]\d{2}/.test(resets),
    language: layout.language,
  });
  break;
}
result;
