#import "/src/main.typ" as tanki

#let did = 1234
#tanki.add-deck(did, "Example", "My Deck")
#let new-note = tanki.add-note.with(deck: did)
#new-note(("What's nine plus ten?", "Twennyone"))
#new-note(("bing", "bong"))
#new-note(("MATHS", $sum_(i=1)^69 v_i dot norm(v), v in RR^69$))

