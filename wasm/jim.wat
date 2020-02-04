(module
  (import "env" "forty_two" (func $forty_two (result i32)))
  (memory 1)
  (func (export "add_forty_two") (param $n i32) (result i32)
        call $forty_two
        local.get $n
        i32.add)
  ;; This function performs ASCII lower casing of values in the range A-Z
  (func (export "to_lower") (param $str i64)
    (local $p i32)
    (local $n i32)
    (local $c i32)
    (local $l i32)
    ;; Convert i64 to offset/length
    (set_local $p (i32.wrap/i64 (get_local $str)))
    (set_local $n (i32.wrap/i64 (i64.shr_u (get_local $str) (i64.const 32))))

    (set_local $l (call $add (get_local $n) (get_local $p)))
    (block
      (loop
        (set_local $c (i32.load8_u (get_local $p)))
        (if (i32.le_u (get_local $c) (i32.const 90))
            (if (i32.ge_u (get_local $c) (i32.const 65))
                (set_local $c (call $lower (get_local $c)))))
        (i32.store8 (get_local $p) (get_local $c))
        (set_local $p (call $increment (get_local $p)))
        (br_if 1 (i32.eq (get_local $p) (get_local $l)))
        (br 0)
      )
    ))
  (func $lower (param $a i32) (result i32)
        local.get $a
        i32.const 32
        i32.add)
  (func $add (param $a i32) (param $b i32) (result i32)
        local.get $a
        local.get $b
        i32.add)
  (func $increment (param $n i32) (result i32)
        local.get $n
        i32.const 1
        i32.add)
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
  (func $free (export "free") (param $addr i64)
        (local $cnt i64)
        (set_local $cnt (i64.div_s (get_local $addr) (i64.const 1024)))
        ;; bit clear the addr count on the global allocated var
        (global.set $allocated (i64.and (global.get $allocated) (i64.xor (i64.const -1) (i64.shl (i64.const 1) (get_local $cnt)))))
        )
  (func $get_allocated (export "get_allocated") (result i64)
        global.get $allocated)
)
