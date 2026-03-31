#import "util.typ": *
#import "/src/main.typ" as ta

#show link: underline.with(stroke: 1pt + blue.lighten(70%))
#set text(font: "FreeSans")

#let VERSION = toml("/typst.toml").package.version

#heading(outlined: false)[tanki #VERSION]

desc ...

#pagebreak()

#outline(depth: 4)

#pagebreak()

= Overview

...

#pagebreak()

= API

#show-module("main")

#show-module("render")
