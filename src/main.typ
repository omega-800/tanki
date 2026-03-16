#import "util.typ": *
#import "model.typ": *

#let tanki(it, format: auto) = context {
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
  } else if format == auto and it.type == "tanki-note" {
    it
  } else if format != none {
    format(it)
  }
}

#let add-note(..args) = {
  let id = args.pos().find(i => type(i) == int)
  id = if id == none {
    /* TODO: auto-increment */
    args.named().at("id", default: 1)
  } else { id }
  let fields = args.pos().find(i => type(i) == array)
  fields = if fields == none { args.named().at("fields", default: ()) } else {
    fields
  }
  let note-obj = note(id: id, fields: fields, ..args.named())
  tanki(note-obj)
}

#let add-deck(format: none, ..args) = {
  let id = if args.pos().len() > 0 { args.pos().at(0) } else { args.named().id }
  let name = if args.pos().len() > 1 { args.pos().at(1) } else {
    args.named().name
  }
  let desc = if args.pos().len() > 2 { args.pos().at(2) } else {
    args.named().desc
  }
  let deck-obj = deck(id: id, name: name, desc: desc, ..args.named())
  tanki(deck-obj)
}
