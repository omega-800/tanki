#import "/src/main.typ" as tanki

#let did = 1234
#tanki.add-deck(did, "Example", "My Deck")
#let new-note = tanki.add-note.with(deck: did)
#new-note(("What's nine plus ten?", "Twennyone"))
#new-note(("bing", "bong"))


