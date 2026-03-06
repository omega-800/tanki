#let card(it) = context {
  if target() == "html" {
    html.elem("div", attrs: (class: "tanki-card"), it)
  } else {
    it
  }
}
