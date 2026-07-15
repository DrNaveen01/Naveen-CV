# Naveen CV

This repository generates an academic curriculum vitae from one structured
data source. CV facts belong in `data/master.yml`; output-specific formatting
belongs in the profile and template files.

## Core workflow

1. Edit `data/master.yml`.
2. Open a terminal in the project directory.
3. Render the required format.

```bash
quarto render cv.qmd --profile html
quarto render cv.qmd --profile word
quarto render cv.qmd --profile typst
quarto render cv.qmd --profile latex
```

From R, all four formats can be rendered with:

```r
source("scripts/render_all.R")
```

Generated files are written to separate folders under `output/`.

## File responsibilities

| File | Responsibility |
|---|---|
| `data/master.yml` | Authoritative CV facts |
| `cv.qmd` | Section selection and order |
| `filters/cv.lua` | Converts structured facts to Pandoc content |
| `_quarto-*.yml` | Output-format settings |
| `templates/word/cv-reference.docx` | Word typography and paragraph styles |
| `styles/cv.css` | HTML appearance |

## Adding information

Copy an existing entry in `data/master.yml`, change its values, and keep its
field names unchanged. Quote dates so YAML does not reinterpret them.

```yaml
appointments:
  - position: "Senior Resident"
    department: "Department name"
    institution: "Institution name"
    location: "City, State"
    start: "2026-02"
    end: "Present"
    include: true
```

Set `include: false` when an entry is incomplete or should remain in the master
record without appearing in the current CV.

## Creating another CV version

Copy `cv.qmd` to a new descriptive filename and change only the entries under
`cv-view: sections:`. Both files will continue to use the same `master.yml`.

## Replacing templates

- Word: replace `templates/word/cv-reference.docx` and preserve the paragraph
  style names used by the repository.
- Typst: add a custom template or Quarto Typst extension in
  `_quarto-typst.yml`.
- LaTeX: add a template, document class, or Quarto extension in
  `_quarto-latex.yml`.

No factual information should be copied into a template.

