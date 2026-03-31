#import "@preview/tidy:0.4.3"
#import "/src/main.typ" as ta
#import "/docs/style.typ"

#let show-module = module => tidy.show-module(
  tidy.parse-module(
    read("/src/" + module + ".typ"),
    scope: (ta: ta),
    preamble: "
    #import ta: *
    ",
  ),
  style: style,
  first-heading-level: 3,
)
