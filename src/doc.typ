#import "./tanki.typ": add-deck, add-note
#import "./util.typ": *

#let start-note = (
  ..args,
  format: none,
  headings-as-tags: true,
  add-first-field: true,
) => metadata((
  type: "tanki:note:start",
  args: args,
  format: format,
  headings-as-tags: headings-as-tags,
  add-first-field: add-first-field,
))

#let end-note = () => metadata((type: "tanki:note:end"))

#let start-field = () => metadata((type: "tanki:field:start"))

#let end-field = () => metadata((type: "tanki:field:end"))

#let add-n = (
  i,
  elem,
  curfields,
  curnotemeta,
  inside-note,
  did,
  body,
  curnoteloc,
) => {
  let lastfield = curfields.last(default: none)
  if lastfield != none and lastfield.len() == 1 {
    curfields.last().push(i)
  }

  if not inside-note {
    panic(
      "Can only add fields inside of note",
      curnotemeta,
      curfields,
      inside-note,
    )
  }
  let wrongfields = curfields.filter(f => f.len() != 2 or f.at(0) > f.at(1))
  if wrongfields.len() > 0 {
    panic("Wrong amount of fields")
  }

  let field-elems = curfields.map(((f, t)) => body.children.slice(f, t).join())

  context add-note(
    deck: did,
    format: curnotemeta.format,
    ..field-elems,
    ..curnotemeta.args,
    tags: (
      ..curnotemeta.at("tags", default: ()),
      ..(
        if curnotemeta.headings-as-tags and curnoteloc != none {
          query(selector(heading).before(curnoteloc.location()))
            .rev()
            .fold((:), prev-headings)
            .values()
        } else { () }
      ),
    ),
  )
}

#let tanki-doc = (deck: none, body) => context {
  body
  // TODO:
  let notectr = 0
  let did = 1
  if deck != none {
    did = deck.id
    add-deck(..deck)
  }
  let inside-note = false
  let curnotemeta = none
  let curfields = ()
  let curnoteloc = none

  for (i, elem) in body.children.enumerate() {
    let meta = elem.at("value", default: none)
    if (
      meta == none
        or type(meta) != dictionary
        or meta.type.match(regex("tanki:.*")) == none
    ) { continue }

    if meta.type == "tanki:note:start" {
      // querying is so goddamn cursed and i love it
      if inside-note {
        context add-n(
          i,
          elem,
          curfields,
          curnotemeta,
          inside-note,
          did,
          body,
          query(metadata)
            .filter(m => m.value.type == "tanki:note:start")
            .at(notectr, default: none),
        )
      }
      inside-note = true
      curfields = if meta.add-first-field { ((i,),) } else { () }
      curnotemeta = meta
      notectr += 1
    } else if meta.type == "tanki:note:end" {
      context add-n(
        i,
        elem,
        curfields,
        curnotemeta,
        inside-note,
        did,
        body,
        query(metadata)
          .filter(m => m.value.type == "tanki:note:start")
          .at(notectr, default: none),
      )
      inside-note = false
      curfields = ()
      curnotemeta = none
    } else if meta.type == "tanki:field:start" {
      // if not inside-note {
      //   inside-note = true
      //   curnotemeta = meta
      // } else {
      let lastfield = curfields.last(default: none)
      if lastfield != none and lastfield.len() == 1 {
        curfields.last().push(i)
      }
      // }
      curfields.push((i,))
    } else if meta.type == "tanki:field:end" {
      curfields.last().push(i)
    }
  }
}
