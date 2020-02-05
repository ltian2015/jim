extern crate peg;

// Import the Filesystem so we can read our .wasm files
use std::fs::read;

//mod codegen;
//mod frontend;

use wasmtime::*;

// Get the path of compiled webassembly
const RUNTIME_WASM_FILE_PATH: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/runtime.wasm");
const JIM_WASM_FILE_PATH: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/jim.wasm");

// Our entry point to our application
fn main() {
        let store = Store::default();

        let runtime_wasm = read(RUNTIME_WASM_FILE_PATH).expect("reading runtime wasm");

        let runtime_module = Module::new(&store, &runtime_wasm).expect("wasm runtime module");

        let jim_wasm = read(JIM_WASM_FILE_PATH).expect("reading jim wasm");

        let jim_module = Module::new(&store, &jim_wasm).expect("wasm jim module");

        // Create env for runtime
        // The order here must match the import order in the WASM module.
        let env: &[Extern] = &[
                Extern::Func(HostRef::new(Func::new(
                        &store,
                        FuncType::new(Box::new([ValType::I64]), Box::new([ValType::I64])),
                        std::rc::Rc::new(Get),
                ))),
                Extern::Func(HostRef::new(Func::new(
                        &store,
                        FuncType::new(Box::new([ValType::I64, ValType::I64]), Box::new([])),
                        std::rc::Rc::new(Set),
                ))),
                Extern::Func(HostRef::new(Func::new(
                        &store,
                        FuncType::new(Box::new([]), Box::new([ValType::I64])),
                        std::rc::Rc::new(Now),
                ))),
                Extern::Func(HostRef::new(Func::new(
                        &store,
                        FuncType::new(Box::new([ValType::I64, ValType::I32]), Box::new([])),
                        std::rc::Rc::new(At),
                ))),
                Extern::Func(HostRef::new(Func::new(
                        &store,
                        FuncType::new(
                                Box::new([ValType::I64, ValType::I64, ValType::I32]),
                                Box::new([]),
                        ),
                        std::rc::Rc::new(Watch),
                ))),
                Extern::Func(HostRef::new(Func::new(
                        &store,
                        FuncType::new(Box::new([]), Box::new([ValType::I32])),
                        std::rc::Rc::new(Wait),
                ))),
        ];

        let runtime = Instance::new(&store, &runtime_module, env).expect("wasm runtime instance");
        let externs = [env, runtime.exports()].concat();
        let jim = Instance::new(&store, &jim_module, &externs).expect("wasm jim instance");
        let entry = jim
                .find_export_by_name("main")
                .expect("find main")
                .func()
                .expect("function");
        println!(
                "Main exit code {}",
                entry.borrow().call(&[]).expect("call main")[0].unwrap_i32()
        );
}

struct Get;

impl wasmtime::Callable for Get {
        fn call(&self, params: &[Val], results: &mut [Val]) -> Result<(), wasmtime::Trap> {
                let mut value = params[0].unwrap_i64();
                value *= 2;
                results[0] = value.into();

                Ok(())
        }
}

struct Set;

impl wasmtime::Callable for Set {
        fn call(&self, params: &[Val], _results: &mut [Val]) -> Result<(), wasmtime::Trap> {
                let mut _path = params[0].unwrap_i64();
                let mut _value = params[1].unwrap_i64();
                Ok(())
        }
}

struct Now;

impl wasmtime::Callable for Now {
        fn call(&self, _params: &[Val], results: &mut [Val]) -> Result<(), wasmtime::Trap> {
                results[0] = (1i64).into();
                Ok(())
        }
}
struct At;

impl wasmtime::Callable for At {
        fn call(&self, params: &[Val], _results: &mut [Val]) -> Result<(), wasmtime::Trap> {
                let mut _time = params[0].unwrap_i64();
                let mut _fn = params[1].unwrap_i32();
                Ok(())
        }
}
struct Watch;

impl wasmtime::Callable for Watch {
        fn call(&self, params: &[Val], _results: &mut [Val]) -> Result<(), wasmtime::Trap> {
                let mut _path = params[0].unwrap_i64();
                let mut _value = params[1].unwrap_i64();
                let mut _fn = params[2].unwrap_i32();
                Ok(())
        }
}
struct Wait;

impl wasmtime::Callable for Wait {
        fn call(&self, _params: &[Val], results: &mut [Val]) -> Result<(), wasmtime::Trap> {
                results[0] = (-1i32).into();
                Ok(())
        }
}
