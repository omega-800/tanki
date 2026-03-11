#import "util.typ": *

#let tanki(it) = context {
  if is-tanki {
    html.elem("div", attrs: (class: "tanki-card"), it)
  } else {
    it
  }
}
