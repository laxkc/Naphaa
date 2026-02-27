import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const tokensDir = path.join(root, "design-system", "tokens");
const outTokensFile = path.join(root, "app", "generated-tokens.css");
const outThemeInlineFile = path.join(root, "app", "generated-theme-inline.css");

function readJson(file) {
  return JSON.parse(fs.readFileSync(path.join(tokensDir, file), "utf8"));
}

const colors = readJson("colors.json");
const typography = readJson("typography.json");
const spacing = readJson("spacing.json");
const radius = readJson("radius.json");
const shadow = readJson("shadow.json");

const tokenLines = [];
tokenLines.push("/*");
tokenLines.push(" * AUTO-GENERATED FILE. Do not edit manually.");
tokenLines.push(" * Source: design-system/tokens/*.json");
tokenLines.push(" * Run: npm run tokens:sync");
tokenLines.push(" */");
tokenLines.push("");
tokenLines.push(":root {");

for (const [key, value] of Object.entries(colors.tokens)) {
  tokenLines.push(`  --ds-color-${key}: ${value};`);
}

for (const [key, value] of Object.entries(spacing.tokens)) {
  tokenLines.push(`  --ds-space-${key}: ${value}px;`);
}

for (const [key, value] of Object.entries(radius.tokens)) {
  const v = key === "pill" ? `${value}px` : `${value}px`;
  tokenLines.push(`  --ds-radius-${key}: ${v};`);
}

for (const [key, value] of Object.entries(shadow.tokens)) {
  tokenLines.push(`  --ds-shadow-${key}: ${value};`);
}

for (const [key, value] of Object.entries(typography.fontFamily ?? {})) {
  tokenLines.push(`  --ds-font-${key}: ${value};`);
}

for (const [tokenName, config] of Object.entries(typography.tokens)) {
  tokenLines.push(`  --ds-type-${tokenName}-size: ${config.size}px;`);
  tokenLines.push(`  --ds-type-${tokenName}-weight: ${config.weight};`);
  tokenLines.push(`  --ds-type-${tokenName}-line-height: ${config.lineHeight}px;`);
}

tokenLines.push("}");
tokenLines.push("");

fs.writeFileSync(outTokensFile, `${tokenLines.join("\n")}\n`);

const themeLines = [];
themeLines.push("/*");
themeLines.push(" * AUTO-GENERATED FILE. Do not edit manually.");
themeLines.push(" * Tailwind v4 @theme inline values generated from design-system tokens.");
themeLines.push(" * Run: npm run tokens:sync");
themeLines.push(" */");
themeLines.push("");
themeLines.push("@theme inline {");
themeLines.push("");
themeLines.push("  /* Primary (25%) */");
themeLines.push(`  --color-primary:       ${colors.tokens["primary"]};`);
themeLines.push(`  --color-primary-hover: ${colors.tokens["primary-hover"]};`);
themeLines.push("");
themeLines.push("  /* Accent (10%) */");
themeLines.push(`  --color-accent:        ${colors.tokens["accent"]};`);
themeLines.push(`  --color-accent-soft:   ${colors.tokens["accent-soft"]};`);
themeLines.push(`  --color-accent-bg:     ${colors.tokens["accent-bg"]};   /* chip / pill backgrounds only */`);
themeLines.push("");
themeLines.push("  /* Semantic (5%) */");
themeLines.push(`  --color-success:       ${colors.tokens["success"]};`);
themeLines.push(`  --color-warning:       ${colors.tokens["warning"]};`);
themeLines.push(`  --color-danger:        ${colors.tokens["error"]};`);
themeLines.push("");
themeLines.push("  /* Neutral (60%) */");
themeLines.push(`  --color-bg:            ${colors.tokens["background"]};   /* app background */`);
themeLines.push(`  --color-surface:       ${colors.tokens["surface"]};   /* cards, panels, navbar */`);
themeLines.push(`  --color-border:        ${colors.tokens["border"]};`);
themeLines.push("");
themeLines.push("  /* Text */");
themeLines.push(`  --color-label:         ${colors.tokens["text-primary"]};   /* primary text */`);
themeLines.push(`  --color-label-sub:     ${colors.tokens["text-emphasis"]};   /* secondary emphasis */`);
themeLines.push(`  --color-muted:         ${colors.tokens["text-secondary"]};   /* secondary text */`);
themeLines.push("");
themeLines.push("  /* Typography scale */");
themeLines.push(`  --text-display:        ${typography.tokens["hero-title"].size}px;`);
themeLines.push(`  --text-page-title:     ${typography.tokens["page-title"].size}px;`);
themeLines.push(`  --text-section-title:  ${typography.tokens["section-title"].size}px;`);
themeLines.push(`  --text-card-title:     ${typography.tokens["card-title"].size}px;`);
themeLines.push(`  --text-body:           ${typography.tokens["body"].size}px;`);
themeLines.push(`  --text-small:          ${typography.tokens["small"].size}px;`);
themeLines.push(`  --text-button:         ${typography.tokens["button"].size}px;`);
themeLines.push(`  --text-total:          ${typography.tokens["total"].size}px;`);
themeLines.push("");
themeLines.push("  /* Spacing — 8pt grid */");
themeLines.push(`  --space-xs:   ${spacing.tokens["xs"]}px;`);
themeLines.push(`  --space-sm:   ${spacing.tokens["sm"]}px;`);
themeLines.push(`  --space-md:   ${spacing.tokens["md"]}px;`);
themeLines.push(`  --space-lg:   ${spacing.tokens["lg"]}px;`);
themeLines.push(`  --space-xl:   ${spacing.tokens["xl"]}px;`);
themeLines.push(`  --space-xxl:  ${spacing.tokens["3xl"]}px;`);
themeLines.push("");
themeLines.push("  /* Radius */");
themeLines.push(`  --radius-sm:   ${radius.tokens["sm"]}px;`);
themeLines.push(`  --radius-md:   ${radius.tokens["md"]}px;`);
themeLines.push(`  --radius-lg:   ${radius.tokens["lg"]}px;`);
themeLines.push(`  --radius-xl:   ${radius.tokens["xl"]}px;`);
themeLines.push(`  --radius-pill: ${radius.tokens["pill"]}px;`);
themeLines.push("");
themeLines.push("  /* Shadow */");
themeLines.push(`  --shadow-card: ${shadow.tokens["md"]};`);
themeLines.push("");
themeLines.push("  /* Font */");
themeLines.push("  --font-sans: var(--font-inter);");
themeLines.push("");
themeLines.push("  /* shadcn/Radix bridge tokens */");
themeLines.push("  --color-background:                  var(--background);");
themeLines.push("  --color-foreground:                  var(--foreground);");
themeLines.push("  --color-card:                        var(--card);");
themeLines.push("  --color-card-foreground:             var(--card-foreground);");
themeLines.push("  --color-popover:                     var(--popover);");
themeLines.push("  --color-popover-foreground:          var(--popover-foreground);");
themeLines.push("  --color-primary-foreground:          var(--primary-foreground);");
themeLines.push("  --color-secondary:                   var(--secondary);");
themeLines.push("  --color-secondary-foreground:        var(--secondary-foreground);");
themeLines.push("  --color-muted-foreground:            var(--muted-foreground);");
themeLines.push("  --color-accent-foreground:           var(--accent-foreground);");
themeLines.push("  --color-destructive:                 var(--destructive);");
themeLines.push("  --color-input:                       var(--input);");
themeLines.push("  --color-ring:                        var(--ring);");
themeLines.push("  --color-chart-1:                     var(--chart-1);");
themeLines.push("  --color-chart-2:                     var(--chart-2);");
themeLines.push("  --color-chart-3:                     var(--chart-3);");
themeLines.push("  --color-chart-4:                     var(--chart-4);");
themeLines.push("  --color-chart-5:                     var(--chart-5);");
themeLines.push("  --color-sidebar:                     var(--sidebar);");
themeLines.push("  --color-sidebar-foreground:          var(--sidebar-foreground);");
themeLines.push("  --color-sidebar-primary:             var(--sidebar-primary);");
themeLines.push("  --color-sidebar-primary-foreground:  var(--sidebar-primary-foreground);");
themeLines.push("  --color-sidebar-accent:              var(--sidebar-accent);");
themeLines.push("  --color-sidebar-accent-foreground:   var(--sidebar-accent-foreground);");
themeLines.push("  --color-sidebar-border:              var(--sidebar-border);");
themeLines.push("  --color-sidebar-ring:                var(--sidebar-ring);");
themeLines.push("  --radius-2xl: calc(var(--radius) + 8px);");
themeLines.push("  --radius-3xl: calc(var(--radius) + 12px);");
themeLines.push("  --radius-4xl: calc(var(--radius) + 16px);");
themeLines.push("}");
themeLines.push("");

fs.writeFileSync(outThemeInlineFile, `${themeLines.join("\n")}\n`);

console.log(`Generated ${path.relative(root, outTokensFile)}`);
console.log(`Generated ${path.relative(root, outThemeInlineFile)}`);
