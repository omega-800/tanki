use wasm_minimal_protocol::*;

use ciborium::{de::from_reader, ser::into_writer};

initiate_protocol!();

#[wasm_func]
pub fn hello() -> Vec<u8> {
    b"Hello from wasm!!!".to_vec()
}


#[derive(serde::Deserialize)]
struct ComplexDataArgs {
    x: i32,
    y: f64,
}

#[wasm_func]
pub fn complex_data(arg: &[u8]) -> Vec<u8> {
    let args: ComplexDataArgs = from_reader(arg).unwrap();
    let sum = args.x as f64 + args.y;
    let mut out = Vec::new();
    into_writer(&sum, &mut out).unwrap();
    out
}
