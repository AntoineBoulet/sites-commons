function Div(el)
  if not el.classes:includes("margin-html-figure") then return nil end

  local base    = el.attributes["base"]
  local caption = el.attributes["caption"] or ""

  local format = quarto.doc.is_format("html") and "html" or "pdf"

  local raw
  if format == "html" then
    raw = string.format([[
::: {.column-margin}
::: {.light-content}
![%s](%s-light.svg){fig-align="center"}
:::
::: {.dark-content}
![%s](%s-dark.svg){fig-align="center"}
:::
:::
]], caption, base, caption, base)
  else
    raw = string.format([[
![%s](%s.pdf){fig-align="center"}
]], caption, base)
  end

  return pandoc.read(raw, "markdown").blocks
end