# Naveen CV

A single-source, multi-format academic CV built with **Quarto**, **YAML**, and a **Pandoc Lua filter**. Factual data, field mappings, CV versions, and document styling are separate.

## Files and responsibilities

| File | Purpose |
|---|---|
| `data/master.yml` | Authoritative CV data; do not enter factual information in templates |
| `config/sections.yml` | Section titles, layouts, field mappings, bullets, and optional links |
| `filters/cv.lua` | Generic renderer that reads the schema and produces Pandoc blocks |
| `cv.qmd` | CV view name, selected sections, and section order |
| `_quarto.yml` | Loads the data and schema and enables the filter |
| `_quarto-*.yml` | Format-specific Quarto configurations |
| `templates/word/cv-reference.docx` | Word paragraph styles |
| `styles/cv.css` | HTML styling |

## Render

From the project directory:

```bash
quarto render cv.qmd --profile html
quarto render cv.qmd --profile word
quarto render cv.qmd --profile typst
quarto render cv.qmd --profile latex
```

Or from R:

```r
source("scripts/render_all.R")
```

Outputs go to distinct folders under `output/`. Quarto and the relevant PDF engine must be installed for those formats.

## Add another entry to an existing section

Edit `data/master.yml` and copy the matching YAML item. For example:

```yaml
appointments:
  - position: "Senior Resident"
    institution: "AIIMS Patna"
    start: "2026"
    end: "Present"
    responsibilities:
      - "Teaching and clinical service"
    include: true
```

Set `include: false` to retain draft/unverified records without rendering them. Dates should be quoted.

## Add a new field to an existing section

Fields in `master.yml` are only displayed when referenced in `config/sections.yml`. For example, to display a research project's `short_name`, change its configuration to:

```yaml
  research_projects:
    title: Research Projects
    layout: entry
    primary: [title]
    secondary: [short_name, role, status]
    details: [setting]
    bullets: details
```

Supported `entry` mappings: `primary` (list), `secondary` (list), `primary_separator`, `secondary_separator`, `details` (list), `bullets` (single field with a YAML list), `link` (field containing full URL), and `show_date: false`. Date rendering uses `date` if provided, otherwise `start` and `end`. Missing values are skipped. All sections skip entries with `include: false`.

## Add a completely new section without editing Lua

**1. Add records to `data/master.yml`:**

```yaml
software_projects:
  - name: "aiimsulator"
    type: "R package"
    role: "Developer"
    status: "In development"
    url: "https://github.com/DrNaveen01"
    details:
      - "Reproducible sample-size calculations"
    include: true
```

**2. Register the presentation schema in `config/sections.yml`:**

```yaml
  software_projects:
    title: Software and Research Tools
    layout: entry
    primary: [name]
    secondary: [type, role, status]
    link: url
    bullets: details
```

**3. Include the section under `cv-view.sections` in `cv.qmd`:**

```yaml
cv-view:
  name: "Full academic CV"
  sections:
    - appointments
    - education
    - software_projects
```

The section appears only when it contains at least one included entry.

## Section layouts

- `entry`: bold primary heading, italic secondary fields, dates, optional details and bullets.
- `citation`: a `citation` field followed by an optional clickable `doi`.
- `skills`: `category` and its `items` list.
- `list`: single text field selected by `text_field` (defaults to `title`).

Custom, complex field layouts may still require extending the Lua renderer; the four layouts cover typical academic CV sections.

## Create a targeted CV

Copy `cv.qmd` to another .qmd and edit its section list/order. To restrict an individual entry to named CV versions, add:

```yaml
views:
  - "Full academic CV"
  - "Fellowship CV"
```

This is an exact match against `cv-view.name`. Entries without `views` appear in every CV version, subject to `include`. To render another .qmd explicitly, use `quarto render my-cv.qmd --profile word`; `_quarto.yml` currently configures the project-wide render list for `cv.qmd` only.

## Contacts and publication details

The identity header supports `professional_email`, `phone`, `orcid` (bare ORCID or full URL), `google_scholar`, `institutional_profile`, `github`, and `linkedin`. Missing contact values are skipped. The publication layout displays the formatted `citation` and DOI link; `pmid` and `status` remain available in YAML but are not automatically shown.

## Maintenance and checks

- Keep source facts in `data/master.yml`.
- Review all provisional information before making a CV public.
- Use correctly formed absolute URLs for links.
- Check each output after changes, particularly page breaks in Word/PDF.
- New unregistered section keys generate a warning on stderr instead of silently disappearing.

See [Pandoc Lua filters](https://pandoc.org/lua-filters.html) and [Quarto project metadata](https://quarto.org/docs/projects/quarto-projects.html#metadata-files).
