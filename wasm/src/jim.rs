// Import the Filesystem so we can read our .wasm file
use std::fs::File;
use std::io::prelude::*;
extern crate peg;

//mod codegen;
//mod frontend;

// Import the wasmer runtime so we can use it
use wasmer_runtime::{error, func, imports, instantiate, Array, Func, WasmPtr};

// Get the path of compiled webassembly
const WASM_FILE_PATH: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/jim.wasm");

// Our entry point to our application
fn main() -> error::Result<()> {
    // Let's read in our .wasm file as bytes

    // Let's open the file.
    let mut file = File::open(WASM_FILE_PATH).expect(&format!("wasm file at {}", WASM_FILE_PATH));

    // Let's read the file into a Vec
    let mut wasm_vec = Vec::new();
    file.read_to_end(&mut wasm_vec)
        .expect("Error reading the wasm file");


    // Prepare imports
    let forty_two = move || -> i32 {42};


    // Our import object, that allows exposing functions to our wasm module.
    // We're not importing anything, so make an empty import object.
    let import_object = imports! {
        "env"=> {
            "forty_two" => func!(forty_two),
        },
    };

    // Let's create an instance of wasm module running in the wasmer-runtime
    let instance = instantiate(&wasm_vec, &import_object)?;

    // Lets get the context and memory of our Wasm Instance
    let wasm_instance_context = instance.context();
    let wasm_instance_memory = wasm_instance_context.memory(0);

    let wasm_buffer_pointer: WasmPtr<u8, Array> = WasmPtr::new(0);

    // Let's write a string to the wasm memory
    let original_string = "WASM is COOL";
    println!("The original string is: {}", original_string);
    // We deref our WasmPtr to get a &[Cell<u8>]
    let memory_writer = wasm_buffer_pointer
        .deref(wasm_instance_memory, 0, original_string.len() as u32)
        .unwrap();
    for (i, b) in original_string.bytes().enumerate() {
        memory_writer[i].set(b);
    }

    // Let's call the exported function that concatenates a phrase to our string.
    let to_lower: Func<(u32,u32)> = instance.func("to_lower").expect("to_lower export");
    to_lower.call(wasm_buffer_pointer.offset(), original_string.len() as u32).unwrap();

    // Read the string from that new pointer.
    let new_string = wasm_buffer_pointer
        .get_utf8_string(wasm_instance_memory, original_string.len() as u32)
        .unwrap();
    println!("The new string is: {}", new_string);

    // Asserting that the returned value from the function is our expected value.
    assert_eq!(new_string, "wasm is cool");

    // Log a success message.
    println!("Success!");

    println!("Using imported functions!");

    let add_forty_two: Func<u32,u32> = instance.func("add_forty_two").expect("add_forty_two export");
    let answer = add_forty_two.call(5).unwrap();
    println!("The answer is: {}", answer);

    // Asserting that the returned value from the function is our expected value.
    assert_eq!(answer, 47);

    // Log a success message.
    println!("Success!");

    // Return OK since everything executed successfully!
    Ok(())
}
