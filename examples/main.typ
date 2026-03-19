#import "/src/main.typ" as ta

#let (
  deck,
  provide-deck,
  add-note,
  add-note-tip,
  add-note-custom,
) = ta.deck-with-models(
  ta.deck(
    "Example",
    "My Deck",
    filename: "deck",
    id: 123456,
  ),
  ta.model(
    "tip",
    ("Question", "Answer", "Tip"),
    (
      (
        "Tip card",
        "{{Question}} ({{Tip}})",
        "{{FrontSide}}<hr id=\"answer\">{{Answer}}",
      ),
    ),
  ),
  ta.model(
    "custom",
    ("Question", "Field1", "Answer", "Field2"),
    (
      (
        "Card 1",
        "{{Question}} <br /> {{Field1}}",
        "{{Answer}} <br /> {{Field2}}",
      ),
    ),
  ),
)

#provide-deck

#let render-default = note => box(stroke: blue, inset: 1em)[

  #note.fields.at(0)

  #line(length: 100%, stroke: blue.lighten(50%))

  #note.fields.at(1)
]

#let custom-tip-note-format = note => block(
  fill: blue.lighten(80%),
  inset: .5em,
  radius: 5%,
)[
  #text(size: 2em, weight: "bold", note.fields.at(0)) #h(2em) #text(
    size: .75em,
    fill: black.lighten(20%),
    [(#note.fields.at(2))],
  )
  #v(1em)
  #align(center, text(size: 1.25em, note.fields.at(1)))
]

= Default note model with custom formatting

#add-note("What's nine plus ten?", "Twennyone", format: render-default)

= Default note model with no formatting

#add-note("bing", "bong")

= Mathemetical equations (no formatting)

#add-note("MATHS", $sum_(i=1)^69 v_i dot norm(v), v in RR^69$)

= Custom model/template (no formatting)

#add-note-tip("What's the capital of Switzerland", "Bern", [It's not Zurich])

= Custom model/template (with formatting)

#add-note-tip(
  "moar maths",
  $x + 2 = 2$,
  $x =^! 0$,
  format: custom-tip-note-format,
)

= Custom model, formatted through the provided anki template

#add-note-custom("I will", "Never", "Kill", "Myself", format: ta.template-note)
