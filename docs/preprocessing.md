# Preprocessing

Before cmark-gfm parses Markdown, `MarkdownPreprocessor.preprocess()` in `src/markdown_preprocessor.vala` applies text transforms in a fixed order.

## Why preprocess?

Some real-world notes (especially from Obsidian or Persian workflows) use syntax that is valid for human readers but confusing for strict parsers. Math delimiters also confuse the Markdown lexer if left in place. Preprocessing fixes known cases without changing the overall Markdown model.

## Steps

Preprocessing runs in this order:

1. `protect_math`
2. `normalize_blockquote_lists`
3. `normalize_list_markers`

## Math protection

LaTeX is extracted and replaced with opaque placeholders **before** any other rewrite. The original LaTeX is stored in `MathRegistry` and restored at render time by `MathWidget`.

### Supported delimiters

| Form | Mode | Example |
|------|------|---------|
| `$…$` | inline | `$E = mc^2$` |
| `$$…$$` | block | `$$\int_0^1 f(x)\,dx$$` |
| `\(...\)` | inline | `\(x^2 + y^2\)` |
| `\[...\]` | block | `\[\sum_{i=1}^n i\] ` |

### Placeholder format

- Block: `⟦BLOCKMATH:0⟧`, `⟦BLOCKMATH:1⟧`, …
- Inline: `⟦INLINEMATH:0⟧`, `⟦INLINEMATH:1⟧`, …

These Unicode bracket characters are unlikely to appear in normal prose, so cmark-gfm treats them as literal text inside paragraphs or standalone blocks.

### Fenced code is skipped

While scanning line by line, lines inside ` ``` ` fences are copied verbatim. That keeps `` `$E=mc^2$` `` in a code block from becoming rendered math.

### Inline `$` rules

Single-dollar inline math requires:

- No space immediately after the opening `$`
- No space immediately before the closing `$`
- The closing `$` must not be escaped

This matches common LaTeX-in-Markdown conventions and avoids currency false positives in many cases.

## Blockquote list normalization

Obsidian and some editors use `--` as a list marker inside blockquotes:

```markdown
> -- first item
> -- second item
```

CommonMark expects `-` for bullet lists. The preprocessor rewrites:

```markdown
> -- item
```

to:

```markdown
> - item
```

Only lines matching the prefix `> -- ` are changed.

## Persian and Arabic digit normalization

Ordered lists with Eastern digits may not parse as lists:

```markdown
۱. اول
۲. دوم
```

The preprocessor converts Persian (`۰`–`۹`) and Eastern Arabic (`٠`–`٩`) digits to ASCII `0`–`9` when they appear in a list-marker pattern:

```text
[optional spaces] DIGITS + ('.' or ')') + space + rest of line
```

After normalization:

```markdown
1. اول
2. دوم
```

## What preprocessing does not do

- It does not fix missing blank lines between blocks.
- It does not rewrite tables or headings.
- It does not implement Obsidian-specific syntax (wikilinks, callouts, embeds).
- It does not parse LaTeX semantics — only extraction and placeholder substitution.

Those require either source changes or future preprocessor rules.

## Adding new rules

To add a rule:

1. Implement a private static method in `markdown_preprocessor.vala`.
2. Call it from `preprocess()` in a deliberate order (math protection should stay first).
3. Document the rule here.
4. Test with `make run FILE=…` on a sample that triggered the issue.

Keep rules small and predictable — preprocessing should not surprise users who rely on strict CommonMark behavior.