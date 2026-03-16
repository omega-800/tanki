#let to-html(it) = {
  if type(it) == array {
    html.elem("ul", it.map(v => html.elem("li", to-html(v))).join())
  } else if type(it) == dictionary {
    html.elem(
      "div",
      attrs: (class: "dict"),
      it.pairs().map(((k, v)) => html.elem(k, to-html(v))).join(),
    )
  } else if it == auto {
    [auto]
  } else {
    str(it)
  }
}
