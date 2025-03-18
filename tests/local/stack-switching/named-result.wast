;;; Ensuring handler result types are adhered to 

;; Correct usage example: 
(module
  (type $ht (handler (result i32 i64 f32 f64)))
  (type $ft (func (param (ref $ht)) (result i32 i64 f32 f64)))
  (type $ct (cont $ft))

  (tag $t)

  (func $g (type $ft)
     (return (i32.const 1) (i64.const 2) (f32.const 3) (f64.const 4)))

  (elem declare func $g)

  (func $f (export "f") (result i32)
     (local $i i32)
     (local $k (ref $ct))
     (local.set $k (cont.new $ct (ref.func $g)))
     (loop $next
      (block $on_t (result (ref $ct))
        (resume_with $ct (on $t $on_t) (local.get $k))
        (drop)
        (drop)
        (drop)
        (local.set $i)
        (return (local.get $i))
      ) ;; on_t
      (unreachable)
    )
    (unreachable)
  )
)
(assert_return (invoke "f") (i32.const 1))


;; Invalid case #1: mismatch in length of number of result types
(assert_invalid
  (module
    (type $ht (handler))
    (type $ft (func (param (ref $ht)) (result i32 i64 f32 f64)))
    (type $ct (cont $ft))

    (tag $t)

    (func $g (type $ft)
      (return (i32.const 1) (i64.const 2) (f32.const 3) (f64.const 4)))

    (elem declare func $g)

    (func $f (export "f") (result i32)
      (local $i i32)
      (local $k (ref $ct))
      (local.set $k (cont.new $ct (ref.func $g)))
      (loop $next
        (block $on_t (result (ref $ct))
          (resume_with $ct (on $t $on_t) (local.get $k))
          (drop)
          (drop)
          (drop)
          (local.set $i)
          (return (local.get $i))
        ) ;; on_t
        (unreachable)
      )
      (unreachable)
    )
  )
  "type mismatch: result type(s) of handler do not match the result type(s) of continuation passed to resume_with")

;; Invalid case #2: wrong ordering 
(assert_invalid
  (module
    (type $ht (handler (result i32 f32 i64 f64)))
    (type $ft (func (param (ref $ht)) (result i32 i64 f32 f64)))
    (type $ct (cont $ft))

    (tag $t)

    (func $g (type $ft)
      (return (i32.const 1) (i64.const 2) (f32.const 3) (f64.const 4)))

    (elem declare func $g)

    (func $f (export "f") (result i32)
      (local $i i32)
      (local $k (ref $ct))
      (local.set $k (cont.new $ct (ref.func $g)))
      (loop $next
        (block $on_t (result (ref $ct))
          (resume_with $ct (on $t $on_t) (local.get $k))
          (drop)
          (drop)
          (drop)
          (local.set $i)
          (return (local.get $i))
        ) ;; on_t
        (unreachable)
      )
      (unreachable)
    )
  )
  "type mismatch: result type(s) of handler do not match the result type(s) of continuation passed to resume_with")

;; Invalid case #2: off by one
(assert_invalid
  (module
    (type $ht (handler(result i32 i64 f64 f64 ) ))
    (type $ft (func (param (ref $ht)) (result i32 i64 f32 f64 )))
    (type $ct (cont $ft))

    (tag $t)

    (func $g (type $ft)
      (return (i32.const 1) (i64.const 2) (f32.const 3) (f64.const 4)))

    (elem declare func $g)

    (func $f (export "f") (result i32)
      (local $i i32)
      (local $k (ref $ct))
      (local.set $k (cont.new $ct (ref.func $g)))
      (loop $next
        (block $on_t (result (ref $ct))
          (resume_with $ct (on $t $on_t) (local.get $k))
          (drop)
          (drop)
          (drop)
          (local.set $i)
          (return (local.get $i))
        ) ;; on_t
        (unreachable)
      )
      (unreachable)
    )
  )
  "type mismatch: result type(s) of handler do not match the result type(s) of continuation passed to resume_with")