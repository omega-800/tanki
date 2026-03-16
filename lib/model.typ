#let card = (
  id: auto,
  note: auto,
  deck: auto,
  // ordinal: auto,
  // due: auto,
  // interval: auto,
  // flags: auto
) => (:)

#let collection = (
  id: auto,
  version: auto,
  // conf: auto,
  models: auto,
  // decks: auto,
  // dconf: auto,
  // tags: auto,
) => (:)

#let note = (
  id: auto,
  guid: auto,
  // model: auto,
  // tags: auto,
  fields: auto,
  sort-field: auto,
  // checksum: auto,
) => (:)

// col->
#let deck = (
  id: auto,
  name: auto,
  desc: auto, // TODO: is-markdown field
  collapsed: auto,
  b-collapsed: auto,
  conf: auto,
) => (:)

// deck->
#let deck-conf = (
  id: auto,
  name: auto,
  autoplay: auto,
  dynamic: auto,
  timer: auto,
  // TODO: ...
  // lapse: auto,
  // new: auto,
) => (:)

// col->
#let model = (
  id: auto,
  name: auto,
  // css: auto,
  deck: auto,
  fields: auto,
  sort-field: auto,
  tags: auto,
  templates: auto,
  type: auto,
) => (:)

// model->
#let field = (
  name: auto,
  font: auto,
  ordinal: auto,
  rtl: auto,
  sticky: auto,
) => (:)

// model->
#let template = (
  answer: auto,
  question: auto,
  b-answer: auto,
  b-question: auto,
  override: auto,
  name: auto,
  ordinal: auto,
) => (:)
