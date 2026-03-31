#import "/src/main.typ" as ta

#show: ta.tanki-doc.with(deck: ta.deck(name: "LaTeX be fuming rn"))

= I will be a tag

== I won't be a tag

=== And me neither

== But i will

#ta.start-note(guid: 69420)

Q: (almost) non-intrusive way

#ta.start-field()

A: to write your docs

#ta.end-note()

#lorem(50)

== I don't want no header tags no more

#ta.start-note(add-first-field: false, headings-as-tags: false)

This won't be in my card

#ta.start-field()

This will be my question

#ta.end-field()

This will be invisible to anki as well

#ta.start-field()

This will be my answer

#ta.end-field()

And this i won't show either

#ta.end-note()


#ta.start-note()
testQ1
#ta.start-field()
testA1
#ta.end-note()

#ta.start-note()
testQ2
#ta.start-field()
testA2
#ta.end-note()
