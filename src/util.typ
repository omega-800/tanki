#let get-pos-or-named(args, pos, name) = if args.pos().len() > pos {
  args.pos().at(pos)
} else {
  args.named().at(name, default: none)
}

#let or-default(value, default) = if (
  value == auto
    or value == none
    or (
      (type(value) == array or type(value) == dictionary) and value.len() == 0
    )
) {
  default
} else {
  value
}

#let gen-id(name) = repr(name).codepoints().map(str.to-unicode).sum()

#let name-and-id(args, name, id) = {
  let name = args.pos().at(0, default: name)
  (
    name,
    or-default(id, gen-id(name)),
  )
}
