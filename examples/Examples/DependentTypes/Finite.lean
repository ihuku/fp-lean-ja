import Examples.Support
import Examples.Classes


book declaration {{{ NatOrBool }}}
  inductive NatOrBool where
    | nat | bool

  abbrev NatOrBool.asType (code : NatOrBool) : Type :=
    match code with
    | .nat => Nat
    | .bool => Bool
stop book declaration


book declaration {{{ decode }}}
  def decode (t : NatOrBool) (input : String) : Option t.asType :=
    match t with
    | .nat => input.toNat?
    | .bool =>
      match input with
      | "true" => some true
      | "false" => some false
      | _ => none
stop book declaration


book declaration {{{ NestedPairs }}}
  inductive NestedPairs where
    | nat : NestedPairs
    | pair : NestedPairs → NestedPairs → NestedPairs

  abbrev NestedPairs.asType : NestedPairs → Type
    | .nat => Nat
    | .pair t1 t2 => asType t1 × asType t2
stop book declaration


book declaration {{{ NestedPairsbeq }}}
  def NestedPairs.beq (t : NestedPairs) (x y : t.asType) : Bool :=
    match t with
    | .nat => x == y
    | .pair t1 t2 => beq t1 x.fst y.fst && beq t2 x.snd y.snd

  instance {t : NestedPairs} : BEq t.asType where
    beq x y := t.beq x y
stop book declaration





book declaration {{{ Finite }}}
  inductive Finite where
    | unit : Finite
    | bool : Finite
    | pair : Finite → Finite → Finite
    | arr : Finite → Finite → Finite

  abbrev Finite.asType : Finite → Type
    | .unit => Unit
    | .bool => Bool
    | .pair t1 t2 => asType t1 × asType t2
    | .arr t1 t2 => asType t1 → asType t2
stop book declaration

def Finite.count : Finite → Nat
  | .unit => 1
  | .bool => 2
  | .pair t1 t2 => count t1 * count t2
  | .arr t1 t2 => count t2 ^ count t1


book declaration {{{ ListProduct }}}
  def List.product (xs : List α) (ys : List β) : List (α × β) := Id.run do
    let mut out : List (α × β) := []
    for x in xs do
      for y in ys do
        out := (x, y) :: out
    pure out.reverse
stop book declaration

def List.concatMap : List α → (α → List β) → List β
  | [], _ => []
  | x :: xs, f => f x ++ xs.concatMap f

namespace ListExtras

book declaration {{{ foldr }}}
  def List.foldr (f : α → β → β) (init : β) : List α → β
    | []     => init
    | a :: l => f a (foldr f init l)
stop book declaration
end ListExtras

evaluation steps {{{ foldrSum }}}
  [1, 2, 3, 4, 5].foldr (· + ·) 0
  ===>
  (1 :: 2 :: 3 :: 4 :: 5 :: []).foldr (· + ·) 0
  ===>
  (1 + 2 + 3 + 4 + 5 + 0)
  ===>
  15
end evaluation steps


-- ANCHOR: MutualStart
mutual
  -- ANCHOR: FiniteAll
  def Finite.all (t : Finite) : List t.asType :=
    match t with
    -- ANCHOR_END: MutualStart
    | .unit => [()]
    | .bool => [true, false]
    | .pair t1 t2 => t1.all.product t2.all
    | .arr t1 t2 => t1.functions t2.all
  -- ANCHOR_END: FiniteAll

  -- ANCHOR: FiniteFunctions
  -- ANCHOR: FiniteFunctionSigStart
  def Finite.functions (t : Finite) (results : List α) : List (t.asType → α) :=
    match t with
  -- ANCHOR_END: FiniteFunctionSigStart
  -- ANCHOR: FiniteFunctionUnit
      | .unit =>
        results.map fun r =>
          fun () => r
  -- ANCHOR_END: FiniteFunctionUnit
  -- ANCHOR: FiniteFunctionBool
      | .bool =>
        (results.product results).map fun (r1, r2) =>
          fun
            | true => r1
            | false => r2
  -- ANCHOR_END: FiniteFunctionBool
  -- ANCHOR: FiniteFunctionPair
      | .pair t1 t2 =>
        let f1s := t1.functions <| t2.functions results
        f1s.map fun f =>
          fun (x, y) =>
            f x y
  -- ANCHOR_END: FiniteFunctionPair
  -- ANCHOR: MutualEnd
  -- ANCHOR: FiniteFunctionArr
      | .arr t1 t2 =>
        let args := t1.all
        let base :=
          results.map fun r =>
            fun _ => r
        args.foldr
          (fun arg rest =>
            (t2.functions rest).map fun more =>
              fun f => more (f arg) f)
          base
  -- ANCHOR_END: FiniteFunctions
  -- ANCHOR_END: FiniteFunctionArr
end
  -- ANCHOR_END: MutualEnd


book declaration {{{ FiniteBeq }}}
  def Finite.beq (t : Finite) (x y : t.asType) : Bool :=
    match t with
    | .unit => true
    | .bool => x == y
    | .pair t1 t2 => beq t1 x.fst y.fst && beq t2 x.snd y.snd
    | .arr t1 t2 => Id.run do
      for arg in t1.all do
        unless beq t2 (x arg) (y arg) do
          return false
      return true
stop book declaration

def Finite.print : (t : Finite) → (x : t.asType) → String
  | .unit, _ => "()"
  | .bool, b => toString b
  | .pair t1 t2, (x, y) => s!"({print t1 x}, {print t2 y})"
  | .arr t1 t2, f =>
    let table := all t1 |>.map fun x => s!"({print t1 x} ↦ {print t2 (f x)})"
    "{" ++ ", ".separate table ++ "}"


def prop (t : Finite) : (Nat × Nat × Bool) := (t.all.length, t.count, t.all.length == t.count)

#eval prop (.arr .bool .unit)
#eval prop (.arr .bool (.pair .unit .bool))
#eval prop (.arr (.arr .bool (.pair (.arr .bool .unit) .bool)) (.pair .unit .bool))
#eval prop (.arr (.arr (.pair .bool .bool) .bool) .bool)



expect info {{{ nestedFunLength }}}
  #eval Finite.all (.arr (.arr (.pair .bool .bool) .bool) .bool) |>.length
message
"65536"
end expect


#eval Finite.all (.arr .bool .unit) |>.map (Finite.print _)
#eval Finite.all (.arr .bool .bool) |>.map (Finite.print _)
#eval Finite.all (.arr (.arr .unit .bool) .bool) |>.map (Finite.print _)


expect info {{{ arrBoolBoolEq }}}
  #eval Finite.beq (.arr .bool .bool) (fun _ => true) (fun b => b == b)
message
"true"
end expect


expect info {{{ arrBoolBoolEq2 }}}
  #eval Finite.beq (.arr .bool .bool) (fun _ => true) not
message
"false"
end expect


expect info {{{ arrBoolBoolEq3 }}}
  #eval Finite.beq (.arr .bool .bool) id (not ∘ not)
message
"true"
end expect