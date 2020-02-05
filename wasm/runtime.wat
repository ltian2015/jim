(module
  (import "env" "get" (func $get (param i64) (result i64)))
  (import "env" "set" (func $set (param i64) (param i64)))
  (import "env" "now" (func $now (result i64)))
  (import "env" "at" (func $at (param i64) (param i32)))
  (import "env" "watch" (func $watch (param i64) (param i64) (param i32)))
  (import "env" "wait" (func $wait (result i32)))
  (memory 1)
  ;; The following implements the most trivial of allocators.
  ;; Memory is allocated in 1024 byte chunks.
  ;; A single 64-bit value ($allocated) is used as a bit mask where a set bit indicates the memory is used.
  ;; Alloc finds the lowest unset bit and returns a i32 pointer offset and records the allocation in the $allocated bit mask.
  ;; Free clears the bit from $allocated for a given pointer value.
  ;; The allocator support only a single 64KB page of memory.
  ;; Memory is zeroed on allocation.
  (global $allocated (mut i64) (i64.const 0))
  (func $alloc (export "alloc") (result i32)
        (local $cnt i64)
        (local $addr i32)
        (local $end i32)
        (set_local $cnt (i64.sub (i64.const 64) (i64.clz (global.get $allocated))))
        ;; bit set the addr count on the global allocated var
        (global.set $allocated (i64.or (global.get $allocated) (i64.shl (i64.const 1) (get_local $cnt))))
        (i64.mul (get_local $cnt) (i64.const 1024))
        i32.wrap/i64
        local.set $addr
        ;; Zero memory
        (set_local $end (i32.add (get_local $addr) (i32.const 1024)))
        (block
          (loop
            (set_local $end (i32.sub (get_local $end) (i32.const 8)))
            (i64.store (get_local $end) (i64.const 0))
            (br_if 1 (i32.eq (get_local $end) (get_local $addr)))
            (br 0)
          )
        )
        (get_local $addr)
        )
  (func $free (export "free") (param $addr i32)
        (local $cnt i64)
        (set_local $cnt (i64.div_s (i64.extend_u/i32 (get_local $addr)) (i64.const 1024)))
        ;; bit clear the addr count on the global allocated var
        (global.set $allocated (i64.and (global.get $allocated) (i64.xor (i64.const -1) (i64.shl (i64.const 1) (get_local $cnt)))))
        )
)
