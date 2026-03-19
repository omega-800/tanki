#import "util.typ": *
#import "render.typ": *

/// Model template
///
/// ```example-??
/// template(question: "{{Question}}", answer: "{{Answer}}")
/// ```
/// -> template
#let template(
  /// Deck id
  /// -> int | auto
  did: auto,
  /// Template name
  /// -> str | auto
  name: auto,
  /// Answer template
  /// -> str | auto
  answer: auto,
  /// Question template
  /// -> str | auto
  question: auto,
  /// Browser answer template. Defaults to @template.answer
  /// -> str | auto
  b-answer: auto,
  /// Browser question template. Defaults to @template.question
  /// -> str | auto
  b-question: auto,

  // TODO:
  /// Custom format
  /// -> function | dict
  format: auto,

  ..args,
) = (
  type: "tanki-template",
  did: did,
  name: name,
  answer: answer,
  question: question,
  b-answer: or-default(b-answer, answer),
  b-question: or-default(b-question, question),

  // format: format
)

/// Model field
///
/// ```example-??
/// field(name: "Question", size: 16)
/// ```
/// -> field
#let field(
  /// Field name
  /// -> str | auto
  name: auto,
  /// Font
  /// -> str
  font: "Liberation Sans",
  /// If text is right to left
  /// -> bool
  rtl: false,
  /// If field is sticky
  /// -> bool
  sticky: false,
  /// Font size
  /// -> int
  size: 20,
  ..args,
) = (
  type: "tanki-field",
  name: name,
  font: font,
  rtl: rtl,
  sticky: sticky,
  size: size,
)

#let parse-field(f) = if type(f) == str { field(name: f) } else { field(..f) }

#let parse-template(t) = if type(t) == array {
  template(name: t.at(0), question: t.at(1), answer: t.at(2))
} else {
  template(..t)
}

/// Model
///
/// ```example-??
/// ```
/// -> model
#let model(
  /// Model id
  /// -> number | auto
  id: auto,
  /// Model name
  /// -> str | auto
  name: auto,
  /// Model fields
  /// -> fields
  fields: (),
  /// Model templates
  /// -> templates
  templates: (),
  /// Extra css
  /// -> str
  css: "",
  /// Model type
  /// -> "FrontBack" | "Cloze"
  model-type: "FrontBack",
  /// Latex code to be prefixed
  /// -> str
  latex-pre: "",
  /// Latex code to be postfixed
  /// -> str
  latex-post: "",
  /// Index of the sort field
  /// -> int | auto
  sort-field-index: auto,
  // TODO:
  /// Custom format
  /// -> function | dict
  format: auto,

  ..args,
) = {
  let (name, id) = name-and-id(args, name, id)
  let fields = args.pos().at(1, default: fields).map(parse-field)
  let templates = args.pos().at(2, default: templates).map(parse-template)
  (
    type: "tanki-model",
    id: id,
    name: name,
    fields: fields,
    templates: templates,
    css: css,
    model-type: model-type,
    latex-pre: latex-pre,
    latex-post: latex-post,
    sort-field-index: sort-field-index,

    // format: format,
  )
}

#let new-model = model

#let note(
  guid: auto,
  fields: (),
  sort-field: false,
  model: auto,
  tags: (),
  deck: auto,

  ..args,
) = {
  let fields = or-default(args.pos(), fields)
  /* TODO: auto-increment */
  let guid = or-default(guid, fields.map(gen-id).sum())
  (
    type: "tanki-note",
    sort-field: sort-field,
    model: if model == auto { model } else { new-model(..model) },
    tags: tags.map(t => t.trim().replace(" ", "_")),
    deck: deck,

    guid: guid,
    fields: fields,
  )
}

#let deck(
  id: auto,
  name: auto,
  filename: auto,
  desc: "",

  ..args,
) = {
  let (name, id) = name-and-id(args, name, id)
  let desc = args.pos().at(1, default: desc)
  (
    type: "tanki-deck",
    id: id,
    name: name,
    desc: desc,

    filename: filename,
  )
}

#let add-deck(..args, format: auto) = render(
  deck(..args.pos(), ..args.named()),
  format: format,
)
#let add-note(..args, format: auto) = render(
  note(..args.pos(), ..args.named()),
  format: format,
)

#let new-deck = deck

#let deck-with-models(
  deck,
  ..models,
) = {
  let deck-obj = new-deck(..deck)
  (
    (
      deck: deck-obj,
      add-deck: add-deck.with(..deck-obj),
      provide-deck: add-deck(..deck-obj),
      new-note: note.with(deck: deck-obj.id),
      add-note: add-note.with(deck: deck-obj.id),
    )
      + models
        .pos()
        .map(m => {
          let model-obj = model(..m)
          let model-key = "model-" + model-obj.name
          (
            (model-key, model-obj),
            (
              "new-note-" + model-obj.name,
              note.with(deck: deck-obj.id, model: model-obj),
            ),
            (
              "add-note-" + model-obj.name,
              add-note.with(deck: deck-obj.id, model: model-obj),
            ),
          )
        })
        .join()
        .to-dict()
  )
}
