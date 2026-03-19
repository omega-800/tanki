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

#add-note("What's nine plus ten?", "Twennyone", format: render-default)

#add-note("bing", "bong")

#add-note("MATHS", $sum_(i=1)^69 v_i dot norm(v), v in RR^69$)

#add-note-tip("What's the capital of Switzerland", "Bern", "It's not Zurich")

#add-note-custom("I will", "Never", "Kill", "Myself", format: ta.template-note)
