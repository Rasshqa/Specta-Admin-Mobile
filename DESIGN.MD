# SPECTA REVELIORA – The Dark Fantasy Festival

## Mission
Create implementation-ready, token-driven UI guidance for SPECTA REVELIORA – The Dark Fantasy Festival that is optimized for consistency, accessibility, and fast delivery across documentation site.

## Brand
- Product/brand: SPECTA REVELIORA – The Dark Fantasy Festival
- URL: https://specta-reveliora.cloud/
- Audience: developers and technical teams
- Product surface: documentation site

## Style Foundations
- Visual style: structured, tokenized, content-first
- Main font style: `font.family.primary=ui-sans-serif`, `font.family.stack=ui-sans-serif, system-ui, sans-serif, Apple Color Emoji, Segoe UI Emoji, Segoe UI Symbol, Noto Color Emoji`, `font.size.base=16px`, `font.weight.base=400`, `font.lineHeight.base=24px`
- Typography scale: `font.size.xs=10px`, `font.size.sm=12px`, `font.size.md=14px`, `font.size.lg=16px`, `font.size.xl=18px`, `font.size.2xl=20px`, `font.size.3xl=24px`, `font.size.4xl=36px`
- Color palette: `color.text.primary=oklch(0.704 0.04 256.788)`, `color.text.secondary=oklch(0.968 0.007 247.896)`, `color.text.tertiary=#ffffff`, `color.text.inverse=oklch(0.869 0.022 252.894)`, `color.surface.base=#000000`, `color.surface.muted=oklch(0.208 0.042 265.755)`, `color.surface.raised=oklch(0.129 0.042 264.695)`, `color.surface.strong=oklab(0 0 0 / 0.4)`
- Spacing scale: `space.1=2px`, `space.2=4px`, `space.3=10px`, `space.4=12px`, `space.5=14px`, `space.6=16px`, `space.7=20px`, `space.8=24px`
- Radius/shadow/motion tokens: `radius.xs=12px`, `radius.sm=16px`, `radius.md=26843500px` | `shadow.1=rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(168, 85, 247, 0.3) 0px 0px 15px 0px`, `shadow.2=rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(168, 85, 247, 0.45) 0px 0px 35px 0px`, `shadow.3=rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(168, 85, 247, 0.4) 0px 0px 30px 0px`, `shadow.4=rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, oklab(0.291 0.080533 -0.125361 / 0.5) 0px 10px 15px -3px, oklab(0.291 0.080533 -0.125361 / 0.5) 0px 4px 6px -4px` | `motion.duration.instant=150ms`, `motion.duration.fast=300ms`, `motion.duration.normal=800ms`

## Accessibility
- Target: WCAG 2.2 AA
- Keyboard-first interactions required.
- Focus-visible rules required.
- Contrast constraints required.

## Writing Tone
Concise, confident, implementation-focused.

## Rules: Do
- Use semantic tokens, not raw hex values, in component guidance.
- Every component must define states for default, hover, focus-visible, active, disabled, loading, and error.
- Component behavior should specify responsive and edge-case handling.
- Interactive components must document keyboard, pointer, and touch behavior.
- Accessibility acceptance criteria must be testable in implementation.

## Rules: Don't
- Do not allow low-contrast text or hidden focus indicators.
- Do not introduce one-off spacing or typography exceptions.
- Do not use ambiguous labels or non-descriptive actions.
- Do not ship component guidance without explicit state rules.

## Guideline Authoring Workflow
1. Restate design intent in one sentence.
2. Define foundations and semantic tokens.
3. Define component anatomy, variants, interactions, and state behavior.
4. Add accessibility acceptance criteria with pass/fail checks.
5. Add anti-patterns, migration notes, and edge-case handling.
6. End with a QA checklist.

## Required Output Structure
- Context and goals.
- Design tokens and foundations.
- Component-level rules (anatomy, variants, states, responsive behavior).
- Accessibility requirements and testable acceptance criteria.
- Content and tone standards with examples.
- Anti-patterns and prohibited implementations.
- QA checklist.

## Component Rule Expectations
- Include keyboard, pointer, and touch behavior.
- Include spacing and typography token requirements.
- Include long-content, overflow, and empty-state handling.
- Include known page component density: links (26), buttons (15), inputs (1), navigation (1), lists (1), tables (1).


## Quality Gates
- Every non-negotiable rule must use "must".
- Every recommendation should use "should".
- Every accessibility rule must be testable in implementation.
- Teams should prefer system consistency over local visual exceptions.
