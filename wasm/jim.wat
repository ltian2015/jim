(module
  (import "env" "forty_two" (func $forty_two (result i32)))
  (memory 1)
  (func (export "add_forty_two") (param $n i32) (result i32)
        call $forty_two
        local.get $n
        i32.add)
  (func (export "to_lower") (param $p i32) (param $n i32)
    (local $c i32)
    (local $l i32)
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
        i32.add))
