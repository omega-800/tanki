#{
  let p = plugin("../rs/hello.wasm")

  assert.eq(str(p.hello()), "Hello from wasm!!!")

  let encoded = cbor.encode((x: 1, y: 2.0))
  let decoded = cbor(p.complex_data(encoded))
  assert.eq(decoded, 3.0)
}
