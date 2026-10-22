-- Schema-driven CV renderer. Section field mappings live in config/sections.yml.
local stringify = pandoc.utils.stringify
local function str(x)
  if x == nil then return "" end
  return stringify(x)
end
local function has(x) return x ~= nil and str(x) ~= "" end
local function enabled(item, view)
  if item.include ~= nil and str(item.include) == "false" then return false end
  if item.views ~= nil and #item.views > 0 then
    for _, v in ipairs(item.views) do
      if str(v) == view then return true end
    end
    return false
  end
  return true
end
local function inlines(text)
  local s = str(text)
  if s == "" then return {} end
  local parsed = pandoc.read(s, "markdown")
  local result = pandoc.List({})
  for _, block in ipairs(parsed.blocks) do
    if block.content then
      if #result > 0 then result:insert(pandoc.Space()) end
      for _, el in ipairs(block.content) do result:insert(el) end
    end
  end
  return result
end
local function styled(content, style, class)
  return pandoc.Div({pandoc.Para(content)}, pandoc.Attr("", {class}, {["custom-style"]=style}))
end
local function join_fields(item, keys, separator)
  local values = {}
  for _, key in ipairs(keys or {}) do
    if has(item[str(key)]) then values[#values+1] = str(item[str(key)]) end
  end
  return table.concat(values, separator or ", ")
end
local function period(item)
  if has(item.date) then return str(item.date) end
  local start, finish = str(item.start), str(item["end"])
  if start ~= "" and finish ~= "" then return start .. "–" .. finish end
  if start ~= "" then return start end
  return finish
end
local function add_separator(out, sep)
  if #out > 0 then
    out:insert(pandoc.Space())
    out:insert(pandoc.Str(sep))
    out:insert(pandoc.Space())
  end
end
local function add_content(out, source)
  for _, el in ipairs(source) do out:insert(el) end
end
local function heading(item, spec)
  local primary = join_fields(item, spec.primary or {}, str(spec.primary_separator) ~= "" and str(spec.primary_separator) or ", ")
  local secondary = join_fields(item, spec.secondary or {}, str(spec.secondary_separator) ~= "" and str(spec.secondary_separator) or ", ")
  if has(spec.date_field) and has(item[str(spec.date_field)]) then
    -- Explicit date field override
  end
  local date_text = (spec.show_date ~= nil and str(spec.show_date) == "false") and "" or period(item)
  if primary == "" and secondary == "" and date_text == "" then return nil end
  local content = pandoc.List({})
  if primary ~= "" then content:insert(pandoc.Strong(inlines(primary))) end
  if secondary ~= "" then
    add_separator(content, "·")
    content:insert(pandoc.Emph(inlines(secondary)))
  end
  if date_text ~= "" then
    add_separator(content, "|")
    add_content(content, inlines(date_text))
  end
  if has(spec.link) and has(item[str(spec.link)]) and primary ~= "" then
    content = pandoc.List({})
    content:insert(pandoc.Strong({pandoc.Link(inlines(primary), str(item[str(spec.link)]))}))
    if secondary ~= "" then
      add_separator(content, "·")
      content:insert(pandoc.Emph(inlines(secondary)))
    end
    if date_text ~= "" then
      add_separator(content, "|")
      add_content(content, inlines(date_text))
    end
  end
  return styled(content, "CV Entry", "cv-entry")
end
local function bullets(items)
  local list = {}
  for _, v in ipairs(items or {}) do
    if has(v) then list[#list+1] = {pandoc.Plain(inlines(v))} end
  end
  if #list == 0 then return nil end
  return pandoc.BulletList(list)
end
local function render_item(item, spec)
  local blocks = {}
  local mode = str(spec.layout)
  if mode == "skills" then
    local category = str(item.category)
    local values = {}
    for _, v in ipairs(item.items or {}) do
      if has(v) then values[#values+1] = str(v) end
    end
    if category ~= "" or #values > 0 then
      local content = pandoc.List({})
      if category ~= "" then
        content:insert(pandoc.Strong(inlines(category .. ":")))
        content:insert(pandoc.Space())
      end
      add_content(content, inlines(table.concat(values, ", ")))
      blocks[#blocks+1] = styled(content, "CV Detail", "cv-skill")
    end
  elseif mode == "citation" then
    local content = pandoc.List(inlines(item.citation))
    if has(item.doi) then
      add_separator(content, "·")
      content:insert(pandoc.Link({pandoc.Str("DOI")}, "https://doi.org/" .. str(item.doi)))
    end
    if #content > 0 then
      blocks[#blocks+1] = styled(content, "CV Detail", "cv-publication")
    end
  elseif mode == "list" then
    local content = inlines(item[str(spec.text_field or "title")])
    if #content > 0 then blocks[#blocks+1] = styled(content, "CV Detail", "cv-detail") end
  else
    local entry = heading(item, spec)
    if entry then blocks[#blocks+1] = entry end
    for _, key in ipairs(spec.details or {}) do
      if has(item[str(key)]) then
        blocks[#blocks+1] = styled(inlines(item[str(key)]), "CV Detail", "cv-detail")
      end
    end
    if has(spec.bullets) then
      local list = bullets(item[str(spec.bullets)])
      if list then blocks[#blocks+1] = list end
    end
  end
  return blocks
end
local function render_identity(meta)
  local result = {}
  local id = meta.identity or {}
  result[#result+1] = styled(inlines(id.full_name), "CV Name", "cv-name")
  local headline = join_fields(id, {"credentials","designation","department","institution","location"}, " · ")
  if headline ~= "" then result[#result+1] = styled(inlines(headline), "CV Headline", "cv-headline") end
  local contact = meta.contact or {}
  local parts = pandoc.List({})
  local function add(label, value, url)
    if not has(value) then return end
    add_separator(parts, "·")
    if url ~= "" then
      parts:insert(pandoc.Link(inlines(label), url))
    else
      add_content(parts, inlines(value))
    end
  end
  local email = str(contact.professional_email)
  add(email, email, email ~= "" and ("mailto:" .. email) or "")
  add(str(contact.phone), contact.phone, has(contact.phone) and ("tel:" .. str(contact.phone):gsub("[^%d+]","")) or "")
  local orcid = str(contact.orcid)
  if orcid ~= "" and not orcid:match("^https?://") then orcid = "https://orcid.org/" .. orcid end
  add("ORCID", contact.orcid, orcid)
  for _, key in ipairs({"google_scholar","institutional_profile","github","linkedin"}) do
    local labels = {google_scholar="Google Scholar",institutional_profile="Institutional profile",github="GitHub",linkedin="LinkedIn"}
    add(labels[key], contact[key], str(contact[key]))
  end
  if #parts > 0 then result[#result+1] = styled(parts, "CV Contact", "cv-contact") end
  if has(id.professional_summary) then
    result[#result+1] = styled(inlines(id.professional_summary), "CV Summary", "cv-summary")
  end
  return result
end
function Pandoc(doc)
  local meta = doc.meta
  local view = meta["cv-view"] or {}
  local view_name = str(view.name)
  local specs = meta["cv-sections"] or {}
  local requested = view.sections or {}
  local blocks = render_identity(meta)
  for _, rawkey in ipairs(requested) do
    local key = str(rawkey)
    local spec = specs[key]
    if spec == nil then
      io.stderr:write("CV warning: no configuration for section '" .. key .. "'\n")
    else
      local entries = meta[key] or {}
      local section_blocks = {}
      for _, item in ipairs(entries) do
        if enabled(item, view_name) then
          for _, block in ipairs(render_item(item, spec)) do
            section_blocks[#section_blocks+1] = block
          end
        end
      end
      if #section_blocks > 0 then
        blocks[#blocks+1] = pandoc.Header(1, inlines(spec.title or key), pandoc.Attr("", {"cv-section"}))
        for _, block in ipairs(section_blocks) do blocks[#blocks+1] = block end
      end
    end
  end
  return pandoc.Pandoc(blocks, meta)
end
