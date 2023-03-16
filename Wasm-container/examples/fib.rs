// rustc +stable --target wasm32-unknown-unknown -O --crate-type=cdylib sum.rs -o sum.rs.wasm
#[no_mangle]
pub extern "C" fn fib(a: u64) -> u64 {
    let mut prev: u64 = 1;
    let mut cur: u64 = 1;
    let mut index: u64 = 2;
    while index < a {
        let tmp: u64 = cur;
        cur = cur + prev;
        prev = tmp;
        index += 1;
    }
    return cur;
}
