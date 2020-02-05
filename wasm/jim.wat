(module
  (import "env" "get" (func $get (param i64) (result i64)))
  (import "env" "set" (func $set (param i64) (param i64)))
  (import "env" "now" (func $now (result i64)))
  (import "env" "at" (func $at (param i64) (param i32)))
  (import "env" "watch" (func $watch (param i64) (param i64) (param i32)))
  (import "env" "wait" (func $wait (result i32)))
  (import "runtime" "alloc" (func $alloc (result i32)))
  (import "runtime" "free" (func $free (param i32)))
  (table 4 funcref)
  (elem (i32.const 0) $start_scene $stop_scene $when_0 $when_0_body)
  (func $exec (param $fn i32)
        (call_indirect (get_local $fn)))
  (func $loop
        (local $fn i32)
        (block
          (loop
            (set_local $fn (call $wait))
            (br_if 1 (i32.lt_s (get_local $fn) (i32.const 0)))
            (call $exec (get_local $fn))
            (br 0)
          )))
  (func $main (export "main") (result i32)
        call $loop
        i32.const 0)
  ;; Start scene
  (func $start_scene
        call $when_0)
  ;; Stop scene
  ;; TODO remove watch added by start
  ;; This probably means that start needs to store the watch index
  ;; And the watch needs to return an index.
  (func $stop_scene )
  ;; when x is y wait 1 set a = b
  ;; TODO implement wait behavior
  (func $when_0
        (call $watch (i64.const 1) (i64.const 2) (i32.const 3)))
  (func $when_0_body
        (i64.const 1) ;; a
        (i64.const 2) ;; b
        call $set)
)
