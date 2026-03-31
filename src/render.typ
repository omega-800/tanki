#import "./util.typ": *

#let escape-regex = r => (
  "*",
  "+",
  "?",
  "|",
  "{",
  ",",
  "(",
  ")",
  "^",
  "$",
  ".",
).fold(r, (acc, cur) => acc.replace(cur, "\\" + cur))

/// Templates a note with the configured Anki template of the note's model
///
/// ```example-??
/// template-note(my-note)
/// ```
/// -> content
#let template-note(
  /// Note to template
  /// -> note
  note, 
  /// Model's template name to apply. Defaults to first template
  /// -> str | auto
  template: auto
) = {
  if note.model == auto {
    note.fields.join([

    ])
  } else {
    let fields = note.model.fields.zip(note.fields)
    let templ = if template == auto { note.model.templates.first() } else {
      note.model.templates.find(t => t.name == template)
    }
    let rg = regex(
      note
        .model
        .fields
        .map(f => "\\{\\{" + escape-regex(f.name) + "\\}\\}")
        .join("|"),
    )
    let apply-templ = t => to-string(t)
      .matches(rg)
      .fold((to-string(t),), (acc, m) => {
        let (parts, rem) = if acc.len() > 1 {
          acc.chunks(acc.len() - 1)
        } else {
          ((), (acc.first(),))
        }
        let res = rem.first().split(m.text)
        let before = res.first()
        let after = res.at(1, default: "")
        let fname = m
          .text
          .replace("{{", "", count: 1)
          .replace("}}", "", count: 1)
        let (field, v) = fields.find(((f, nf)) => f.name == fname)
        (
          ..parts,
          before,
          text(
            dir: if field.rtl { rtl } else { ltr },
            // font: field.font,
            // size: field.size * 1pt,
            v,
          ),
          after,
        )
      })
      .join()
    // TODO: FrontSide etc
    [
      #apply-templ(templ.question)

      #apply-templ(templ.answer)
    ]
  }
}

#let to-html(it, class: "") = {
  if type(it) == array {
    html.elem(
      "ul",
      it.map(v => html.elem("li", attrs: (class: class), to-html(v))).join(),
    )
  } else if type(it) == dictionary {
    html.elem(
      "div",
      attrs: (
        class: class + " dict " + (if "type" in it { it.type } else { "" }),
      ),
      it.pairs().map(((k, v)) => html.elem(k, to-html(v))).join(),
    )
  } else if type(it) == content {
    it
    // TODO: check if repr works as expected
  } else if type(it) == bool or it == auto or it == none {
    repr(it)
  } else {
    str(it)
  }
}

#let render(it, format: auto, anki-format: auto) = context {
  let anki-format = or-default(anki-format, it => it)
  if (
    "html" in std
      and target() == "html"
      and "tanki" in sys.inputs
      and sys.inputs.tanki == "true"
  ) {
    html.elem(
      it.type,
      attrs: (class: "tanki-elem")
        + (if "id" in it { (id: str(it.id)) } else {}),
      anki-format(it)
        .pairs()
        .map(((k, v)) => html.elem(k, to-html(v, class: it.type)))
        .join(),
    )
  } else if format != none {
    if format != auto {
      format(it)
    } else if it.type == "tanki-note" {
      // template-note(it)
      it.fields.join([

      ])
    }
  }
}
