# tAnki

A typst plugin + rust binary to programmatically generate anki decks from typst sourcecode.

This implementation is quick and dirty but it works. Maybe a cleaner implementation will follow. Maybe not. Deal with it.

## usage

### typst package

#### functions

```typst
#import "@local/tanki:0.0.1" as ta

#let did = 1234
#ta.add-deck("bigbrain", "this will make me smarter than einstein", id: did)
#let note = ta.add-note.with(deck: did) 

#note("Who is the most handsome developer on this planet?", "omega-800")
```

See [examples](./examples/main.typ) for more examples.

#### show rule

```typst
#import "@local/tanki:0.0.1" as ta

#show: ta.tanki-doc.with(deck: ta.deck(name: "Wow this is so much easier"))

= Headings as tags are still a bit buggy just so you know

#ta.start-note()
Who is the most handsome developer on this planet?
#ta.start-field()
omega-800
#ta.end-note()
```

See [show rule examples](./examples/show-rule.typ) for more examples.

### binary

```sh
tanki <path-to-typst-file>
```
