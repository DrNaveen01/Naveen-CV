-- Build a CV from data/master.yml using format-neutral Pandoc elements.

local stringify = pandoc.utils.stringify

local function value(x)
  if x == nil then
    return ""
  end
  return stringify(x)
end

local function present(x)
  return x ~= nil and value(x) ~= ""
end

local function included(item)
  if item == nil then
    return false
  end
  if item.include == nil then
    return true
  end
  return value(item.include) ~= "false"
end

local function add_space(inlines)
  if #inlines > 0 then
    table.insert(inlines, pandoc.Space())
  end
end

local function append_text(inlines, text)
  if text ~= nil and text ~= "" then
    local parsed = pandoc.read(text, "markdown").blocks
    if #parsed > 0 and parsed[1].content ~= nil then
      for _, inline in ipairs(parsed[1].content) do
        table.insert(inlines, inline)
      end
    else
      table.insert(inlines, pandoc.Str(text))
    end
  end
end

local function append_separator(inlines, separator)
  if #inlines > 0 then
    table.insert(inlines, pandoc.Space())
    table.insert(inlines, pandoc.Str(separator))
    table.insert(inlines, pandoc.Space())
  end
end

local function styled_para(inlines, style_name, class_name)
  local attr = pandoc.Attr(
    "",
    {class_name},
    {["custom-style"] = style_name}
  )
  return pandoc.Div({pandoc.Para(inlines)}, attr)
end

local function plain_inlines(text)
  local out = {}
  append_text(out, text)
  return out
end

local function period(item)
  if present(item.date) then
    return value(item.date)
  end

  local start_date = value(item.start)
  local end_date = value(item["end"])

  if start_date ~= "" and end_date ~= "" then
    return start_date .. "–" .. end_date
  elseif start_date ~= "" then
    return start_date
  else
    return end_date
  end
end

local function entry_heading(primary, secondary, date_text)
  local inlines = {}

  if primary ~= "" then
    table.insert(inlines, pandoc.Strong(plain_inlines(primary)))
  end

  if secondary ~= "" then
    append_separator(inlines, "·")
    table.insert(inlines, pandoc.Emph(plain_inlines(secondary)))
  end

  if date_text ~= "" then
    append_separator(inlines, "|")
    append_text(inlines, date_text)
  end

  return styled_para(inlines, "CV Entry", "cv-entry")
end

local function detail_para(text)
  return styled_para(plain_inlines(text), "CV Detail", "cv-detail")
end

local function detail_list(items)
  local output = {}
  if items == nil then
    return output
  end

  local bullets = {}
  for _, item in ipairs(items) do
    local text = value(item)
    if text ~= "" then
      table.insert(bullets, {pandoc.Plain(plain_inlines(text))})
    end
  end

  if #bullets > 0 then
    table.insert(output, pandoc.BulletList(bullets))
  end
  return output
end

local function add_blocks(target, source)
  for _, block in ipairs(source) do
    table.insert(target, block)
  end
end

local function institution_line(item)
  local parts = {}
  for _, key in ipairs({"department", "institution", "university", "location"}) do
    if present(item[key]) then
      table.insert(parts, value(item[key]))
    end
  end
  return table.concat(parts, ", ")
end

local function section_header(title)
  return pandoc.Header(1, plain_inlines(title), pandoc.Attr("", {"cv-section"}))
end

local function render_appointments(items)
  local blocks = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      table.insert(blocks, entry_heading(
        value(item.position),
        institution_line(item),
        period(item)
      ))
      add_blocks(blocks, detail_list(item.responsibilities))
    end
  end
  return blocks
end

local function render_education(items)
  local blocks = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      local degree = value(item.degree)
      if present(item.specialty) then
        degree = degree .. ", " .. value(item.specialty)
      end
      table.insert(blocks, entry_heading(degree, institution_line(item), period(item)))
      if present(item.distinction) then
        table.insert(blocks, detail_para(value(item.distinction)))
      end
    end
  end
  return blocks
end

local function render_research(items)
  local blocks = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      local secondary = value(item.role)
      if present(item.status) then
        if secondary ~= "" then
          secondary = secondary .. "; " .. value(item.status)
        else
          secondary = value(item.status)
        end
      end
      table.insert(blocks, entry_heading(value(item.title), secondary, ""))
      if present(item.setting) then
        table.insert(blocks, detail_para(value(item.setting)))
      end
      add_blocks(blocks, detail_list(item.details))
    end
  end
  return blocks
end

local function render_publications(items)
  local blocks = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      local citation = plain_inlines(value(item.citation))
      if present(item.doi) then
        append_separator(citation, "·")
        table.insert(citation, pandoc.Link(
          {pandoc.Str("DOI")},
          "https://doi.org/" .. value(item.doi)
        ))
      end
      table.insert(blocks, styled_para(citation, "CV Detail", "cv-publication"))
    end
  end
  return blocks
end

local function render_teaching(items)
  local blocks = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      local secondary = institution_line(item)
      table.insert(blocks, entry_heading(value(item.activity), secondary, period(item)))
      add_blocks(blocks, detail_list(item.details))
    end
  end
  return blocks
end

local function render_workshops(items)
  local blocks = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      table.insert(blocks, entry_heading(
        value(item.title),
        value(item.provider),
        period(item)
      ))
    end
  end
  return blocks
end

local function render_awards(items)
  local blocks = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      table.insert(blocks, entry_heading(
        value(item.title),
        value(item.organisation),
        period(item)
      ))
      if present(item.description) then
        table.insert(blocks, detail_para(value(item.description)))
      end
    end
  end
  return blocks
end

local function render_service(items)
  local blocks = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      table.insert(blocks, entry_heading(
        value(item.role),
        value(item.organisation),
        period(item)
      ))
      add_blocks(blocks, detail_list(item.details))
    end
  end
  return blocks
end

local function render_memberships(items)
  local blocks = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      table.insert(blocks, entry_heading(
        value(item.organisation),
        value(item.role),
        period(item)
      ))
    end
  end
  return blocks
end

local function render_skills(items)
  local inlines = {}
  for _, item in ipairs(items or {}) do
    if included(item) then
      if #inlines > 0 then
        table.insert(inlines, pandoc.LineBreak())
      end
      table.insert(inlines, pandoc.Strong(plain_inlines(value(item.category) .. ":")))
      add_space(inlines)
      local skill_values = {}
      for _, skill in ipairs(item.items or {}) do
        table.insert(skill_values, value(skill))
      end
      append_text(inlines, table.concat(skill_values, ", "))
    end
  end

  if #inlines == 0 then
    return {}
  end

  return {styled_para(inlines, "CV Detail", "cv-skill")}
end

local renderers = {
  appointments = {title = "Professional Appointments", fn = render_appointments},
  education = {title = "Education", fn = render_education},
  research_projects = {title = "Research Projects", fn = render_research},
  publications = {title = "Publications", fn = render_publications},
  teaching = {title = "Teaching and Resource-Person Experience", fn = render_teaching},
  workshops = {title = "Selected Workshops and Training", fn = render_workshops},
  awards = {title = "Awards and Honours", fn = render_awards},
  professional_service = {title = "Professional and Public-Health Service", fn = render_service},
  memberships = {title = "Professional Memberships", fn = render_memberships},
  skills = {title = "Methods and Technical Skills", fn = render_skills}
}

local function contact_inlines(contact)
  local items = {}

  local function add_contact(label, text, target)
    if text == "" then
      return
    end
    if #items > 0 then
      append_separator(items, "·")
    end
    if target ~= nil and target ~= "" then
      table.insert(items, pandoc.Link({pandoc.Str(label)}, target))
    else
      append_text(items, text)
    end
  end

  if contact == nil then
    return items
  end

  local email = value(contact.professional_email)
  add_contact(email, email, email ~= "" and ("mailto:" .. email) or "")
  add_contact("ORCID", value(contact.orcid), value(contact.orcid))
  add_contact("Google Scholar", value(contact.google_scholar), value(contact.google_scholar))
  add_contact("Institutional profile", value(contact.institutional_profile), value(contact.institutional_profile))
  add_contact("GitHub", value(contact.github), value(contact.github))
  add_contact("LinkedIn", value(contact.linkedin), value(contact.linkedin))

  return items
end

local function render_identity(meta)
  local blocks = {}
  local identity = meta.identity or {}

  table.insert(blocks, styled_para(
    plain_inlines(value(identity.full_name)),
    "CV Name",
    "cv-name"
  ))

  local headline = {}
  for _, key in ipairs({"credentials", "designation", "department", "institution", "location"}) do
    if present(identity[key]) then
      if #headline > 0 then
        append_separator(headline, "·")
      end
      append_text(headline, value(identity[key]))
    end
  end
  if #headline > 0 then
    table.insert(blocks, styled_para(headline, "CV Headline", "cv-headline"))
  end

  local contacts = contact_inlines(meta.contact)
  if #contacts > 0 then
    table.insert(blocks, styled_para(contacts, "CV Contact", "cv-contact"))
  end

  if present(identity.professional_summary) then
    table.insert(blocks, styled_para(
      plain_inlines(value(identity.professional_summary)),
      "CV Summary",
      "cv-summary"
    ))
  end

  return blocks
end

local function requested_sections(meta)
  local view = meta["cv-view"] or {}
  if view.sections ~= nil then
    return view.sections
  end
  return {
    "appointments", "education", "research_projects", "publications",
    "teaching", "workshops", "awards", "professional_service",
    "memberships", "skills"
  }
end

function Pandoc(doc)
  local blocks = render_identity(doc.meta)

  for _, section_meta in ipairs(requested_sections(doc.meta)) do
    local key = value(section_meta)
    local renderer = renderers[key]
    if renderer ~= nil then
      local content = renderer.fn(doc.meta[key])
      if #content > 0 then
        table.insert(blocks, section_header(renderer.title))
        add_blocks(blocks, content)
      end
    end
  end

  return pandoc.Pandoc(blocks, doc.meta)
end
