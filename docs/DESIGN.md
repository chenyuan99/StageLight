# 剧光灯 StageLight — Design System & UX v0.1

## Design Direction

StageLight should feel Apple-like, minimalist, and premium: **editorial, quiet, personal, and cinematic**. Photography, generous whitespace, native typography, subtle motion, restrained surfaces, and minimal card chrome establish the character.

Avoid red-curtain clichés, gold ornamental borders, repeated theatre masks, neon Broadway aesthetics, noisy gradients, gaming-style confetti, and dashboard-heavy visual design. The interface frames a personal archive; it does not compete with it.

## Brand

- **Chinese name:** 剧光灯
- **English name:** StageLight
- **Tagline:** Your life on stage.
- **Supporting copy:** Remember every curtain call.

## Visual Language

### Light Mode

Light mode feels like a warm gallery page: soft off-white behind crisp photography, near-black type, white surfaces, and quiet separators.

| Token | Value |
| --- | --- |
| Background | `#F7F7F5` |
| Primary | `#111111` |
| Secondary | `#777777` |
| Surface | `#FFFFFF` |
| Separator | `#E7E7E5` |

### Dark Mode

Dark mode evokes a theatre before curtain: deep neutral backgrounds, subtly raised surfaces, and warm, legible content without pure-white glare.

| Token | Value |
| --- | --- |
| Background | `#090909` |
| Surface | `#151515` |
| Primary | `#F5F5F5` |
| Secondary | `#929292` |

A warm ivory or warm-white **Spotlight** accent may mark focus or reveal. Use it sparingly; it is an atmospheric cue, not a general brand color. Validate all final semantic color pairings for accessibility.

## Typography

Use SF Pro through native SwiftUI text styles and support Dynamic Type. Large editorial headings provide identity; smaller system styles preserve clarity.

| Role | Suggested size |
| --- | ---: |
| Display | 34–44 pt |
| Title | 28 pt |
| Headline | 20 pt |
| Body | 17 pt |
| Secondary | 15 pt |
| Caption | 12 pt |

Favor meaningful type over boxed UI. A statistic such as “63 performances” should usually be an oversized number with a modest label, not a KPI card.

## Spacing

Use the shared spacing scale consistently: **4, 8, 12, 16, 24, 32, 48, 64 pt**. Default content margins should feel generous, and related text should sit closer together than separate sections.

## Radius

- Photo: **16 pt**
- Button: **14 pt**
- Sheet: **24 pt**

These values are defaults; native system containers should retain platform-appropriate behavior.

## Motion

- Fast: **0.20 s** for direct feedback
- Standard: **0.35 s** for state transitions
- Reveal: **0.55 s** for intentional content arrival

The motion language is **Spotlight → Reveal**: focus moves gently to important content, which appears with controlled opacity and scale. Motion must never delay input, and Reduce Motion replaces spatial or scale-heavy transitions with restrained fades.

## Main Screens

### Collection

Collection is the default screen. A two-column photo grid makes the photo itself the card, with minimal borders and no unnecessary container behind it. The show title sits below the image; performance count and rating form a quiet secondary line. Consistent crops and generous gutters create rhythm without making the archive feel mechanical.

### Add Sheet

The sheet title is **Add to Your Stage**. Three large, clearly labeled actions appear in this order:

1. Scan
2. Choose from Photos
3. Add Manually

Each action uses an SF Symbol and plain-language supporting text. The sheet should be compact enough to preserve context behind it.

### Camera

Use a minimal, system-camera-like interface with a clear shutter, dismiss action, photo-library entry, and an unobtrusive framing guide.

Helper text:

> Point your camera at a Playbill, ticket, or poster.

### Recognition Loading

Use calm progress motion and the copy:

> Finding your show…

Do not expose implementation language such as “Processing image with AI.” Provide a path to cancel, recover, or add manually if recognition is slow or unavailable.

### Recognition Result

Lead with:

> We found your show

Example result:

**Hamilton**<br>
Richard Rodgers Theatre<br>
August 24, 2026<br>
7:00 PM

Primary CTA: **Add to Stage**<br>
Secondary action: **Edit details**

For low-confidence results, ask **Is this your show?** and emphasize editing. Never display raw confidence percentages to users.

### Add/Edit Performance

Avoid a long database-style form. Reveal fields progressively, foregrounding show title, date, theatre, and rating, with seat, notes, and photos following naturally. Use appropriate pickers and preserve user input while moving between steps.

Notes placeholder:

> What will you remember?

Primary CTA: **Add to Stage**. In edit mode, use **Save Changes** to accurately describe the action.

### Show Detail

Open with a large cover image, title, seen count, and average rating. Follow with a performance timeline. Use whitespace and separators rather than repeated cards so multiple visits read as one evolving history.

### Performance Detail

Use an Apple Journal-inspired editorial hierarchy:

1. date
2. show title
3. theatre
4. hero photo
5. rating
6. seat
7. notes
8. gallery

The page should feel like revisiting a memory, while edit and delete remain discoverable through familiar controls.

### Diary

Diary is an editorial timeline grouped by year and month. Date occupies one visual column and content another, making time easy to scan. Images and typography provide variation while alignment maintains continuity.

### Profile

Profile is not a dashboard. Use oversized numbers and small labels, with a few conversational summaries and ample negative space. For example:

> **63**<br>
> performances

> 47 shows · 22 theatres

### Empty State

Use a subtle spotlight illustration and the copy:

> **Your stage is empty.**<br>
> Every show starts with a moment worth remembering.

CTA: **Add your first show**

## App Icon

Use a minimal black square containing an abstract white spotlight and a small illuminated stage area. The silhouette should remain recognizable at small sizes. Do not use theatre masks or ornamental Broadway motifs.

## Accessibility

- Support Dynamic Type without truncating essential content or actions.
- Provide descriptive VoiceOver labels, values, hints, and logical reading order.
- Maintain minimum 44 × 44 pt touch targets.
- Never rely on color alone to communicate selection, errors, ratings, or status.
- Honor Reduce Motion and avoid motion-dependent meaning.
- Test contrast in both themes, including over photography.
