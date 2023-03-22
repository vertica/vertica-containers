// rustc +stable --target wasm32-unknown-unknown -O --crate-type=cdylib sum.rs -o sum.rs.wasm
#[no_mangle]
pub extern "C" fn sum(a: u32, b: u32) -> u32 {
    return a + b;
}
