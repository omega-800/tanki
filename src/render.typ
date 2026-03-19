#let template-note(note, template: auto) = {
  if note.model == auto {
    note.fields.join([

    ])
  } else {
    let fields = note.model.fields.zip(note.fields)
    let templ = if template == auto { note.model.templates.first() } else {
      note.model.templates.find(t => t.name == template)
    }
    let rg = regex(note.model.fields.map(f => "{{" + f.name + "}}").join("|"))
    let apply-templ = t => t
      .matches(rg)
      .fold((), (acc, (start, end, text)) => acc)
      .join()
    // let apply-templ = t => fields
    //   .fold(
    //     (t,),
    //     (acc, (k, v)) => acc
    //       .map(n => {
    //         n
    //           .split("{{" + k.name + "}}")
    //           .intersperse(text(
    //             dir: if k.rtl { rtl } else { ltr },
    //             font: k.font,
    //             size: k.size * 1pt,
    //             v,
    //           ))
    //       })
    //       .join(),
    //     // acc.replace( "{{" + k.name + "}}", v,)
    //   )
    //   .join()
    // TODO: FrontSide etc
    [
      #apply-templ(templ.question)

      #apply-templ(templ.answer)
    ]
  }
}

#let render(it, format: auto) = context {
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
      it.pairs().map(((k, v)) => html.elem(k, to-html(v))).join(),
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

#let to-html(it) = {
  if type(it) == array {
    html.elem("ul", it.map(v => html.elem("li", to-html(v))).join())
  } else if type(it) == dictionary {
    html.elem(
      "div",
      attrs: (class: "dict"),
      it.pairs().map(((k, v)) => html.elem(k, to-html(v))).join(),
    )
  } else if type(it) == content {
    it
    // TODO: repr instead of str
  } else if it == auto {
    [auto]
  } else {
    str(it)
  }
}
