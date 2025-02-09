;; temporary testing file 
;; (module
;;   (tag $e (param i32))

;;   (type $ht (handler))
;;   (type $f (func (param (ref $ht))))
;;   (type $g (func (param)))
;;   (type $k (cont $f))
;;   (type $k2 (cont $g))
  
;;   (func $g (type $g))

;;   (func $f (type $f)
;;     (suspend_to $ht $e (i32.const 1) (local.get 0))
;;     (drop) ;; drop named handler
;;   )

;;   (func (export "handled_proper")
;;     (block $h (result i32 (ref $k2))
;;       (resume_with $k2 (on $e $h) (cont.new $k2 (ref.func $)))
;;       (unreachable)
;;     )
;;     (drop)
;;     (drop)
;;   ) 
  
;;   (elem declare func $f $g)
;; )
;;(assert_return (invoke "handled_proper"))

;; Nested
;; (module
;;   (type $ht (handler))
;;   (type $ft (func (param (ref $ht))))
;;   ;;(type $ft (func (result i32)))
;;   (type $ct (cont $ft))

;;   (tag $ask (result i32))
    
;;   (func $f (type $ft)
;;     (local $a i32)
;;     (local $b i32)
;;     (local $h (ref $ht))
;;     (local.set $h (local.get 0))
;;     (suspend $ask (local.get $h))
;;     ;;(suspend $ask)
;;     (local.set $a)
;;     (suspend $ask (local.get $h))
;;     ;;(suspend $ask)
;;     (local.set $b)
;;     (i32.add)
;;   )

;;   (func (export "run") (result i32)
;;     (local $i i32)
;;     (local $j i32)
;;     (local $k (ref $ct))
;;     (local.set $k (cont.new $ct (ref.func $f)))
;;     (loop $loop
;;       (block $on_ask (result i32 (ref $ct))
;;         (block $on_ask (result i32 (ref $ct))
;;           (resume_with $ct (on $ask $on_ask) (on $ask $on_ask) (local.get $k))
;;           (local.set $i)
;;           (return)
;;         )
;;         ;; on ask (inner)
;;         (local.set $k)
;;         (local.get $i)
;;         (br $loop)
;;       )
;;       ;; on ask (outer)
;;       (local.set $k)
;;       (local.get $j)
;;       (br $loop)
;;     )
;;     (return (local.get $i))
;;   )

;;   (elem declare func $f)
;; )
;; (assert_return (invoke "run") (i32.const 84))

(module
  (type $ht (handler))

	(type $ft_client (func (param (ref $ht) (ref $ht))))
	(type $ct_client (cont $ft_client))

	(type $ft_inner (func (param (ref $ct_client) (ref $ht))))
	(type $ct_inner (cont $ft_inner))

	(type $ft_client_ask (func (param i32) (param (ref $ht))))
	(type $ct_client_ask (cont $ft_client_ask))

  (func $print-i32 (import "spectest" "print_i32") (param i32))

  ;; Control tag 
  (tag $ask (result i32))

  (func $client (param $hname_inner (ref $ht)) (param $hname_outer (ref $ht))
    (local $a i32)
    (suspend_to $ht $ask (local.get $hname_inner)) 
    ;; name and then return 
    (local.set $hname_inner)
    (local.set $a)
    (suspend_to $ht $ask (local.get $hname_outer)) 
    (local.set $hname_outer)
    ;; adds and puts in a
    (i32.add (local.get $a))
    (call $print-i32)
  )

  (func $environ-outer (param $k (ref $ct_inner)) (param $k_client (ref $ct_client))
    (local $k_ask (ref $ct_client_ask))
    (block $on_ask (result (ref $ct_client_ask)) 
        (resume_with $ct_inner (on $ask $on_ask) (local.get $k_client) (local.get $k))
        (return)
    ) 
    (local.set $k_ask)
    (loop $loop 
        (block $on_ask (result (ref $ct_client_ask)) 
            (resume_with $ct_client_ask (on $ask $on_ask) (i32.const 0) (local.get $k_ask))
            (return)
        ) ;; on_ask
        (local.set $k_ask)
        (br $loop)
  ))

  (func $environ-inner (param $k (ref $ct_client)) (param $houter (ref $ht))
    (local $k_ask (ref $ct_client_ask))
    (block $on_ask (result (ref $ct_client_ask)) 
        (resume_with $ct_client (on $ask $on_ask) (local.get $houter) (local.get $k))
        (return)
    ) 
    (local.set $k_ask)
    (loop $loop 
        (block $on_ask (result (ref $ct_client_ask)) 
            (resume_with $ct_client_ask (on $ask $on_ask) (i32.const 42) (local.get $k_ask))
            (return)
        ) ;; on_ask
        (local.set $k_ask)
        (br $loop)
    ))

	(elem declare func $client $environ-inner $environ-outer)

  (func (export "main") 
    (call $environ-outer (cont.new $ct_inner (ref.func $environ-inner)) (cont.new $ct_client (ref.func $client)))
	)
)
(assert_return (invoke "main"))