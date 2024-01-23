import Mathlib.GroupTheory.PresentedGroup
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.GroupTheory.Subgroup.Basic
import Mathlib.Tactic.Linarith.Frontend

import Coxeter.Auxi
open Classical

section CoeM
universe u
variable {α β : Type u}  [(a :α) -> CoeT α a β]

lemma coeM_nil_eq_nil  : (([] : List α) : List β) = ([]:List β)  := by rfl


@[simp]
lemma coeM_cons {hd : α}  {tail : List α} : ( (hd::tail : List α) : List β) = (hd : β) :: (tail : List β) := by {
  rfl
}


@[simp]
lemma coeM_append  {l1 l2: List α} : ((l1 ++ l2): List β) = (l1 : List β ) ++ (l2 : List β ):= by simp only [Lean.Internal.coeM, List.bind_eq_bind, List.append_bind]


@[simp]
lemma coeM_reverse {l: List α} : (l.reverse: List β) = (l: List β ).reverse := by
  induction l with
  | nil  => trivial
  | cons hd tail ih => simp; congr

@[simp]
lemma mem_subtype_list {x : α}  {S : Set α} {L : List S}: x ∈ (L : List α) → x ∈ S := by {
  intro H
  induction L with
  | nil => trivial
  | cons hd tail ih => {
    simp only [coeM_cons, List.mem_cons] at H
    cases H with
    | inl hh => {
      have :CoeT.coe hd = (hd :α) := rfl
      simp only [hh, this, Subtype.coe_prop]
    }
    | inr hh => {exact ih hh}
  }
}

end CoeM


section list_properties

variable {G : Type _} [Group G] {S: Set G}

@[coe]
abbrev List.gprod {S : Set G} (L : List S) := (L : List G).prod

instance List.ListGtoGroup : CoeOut (List G) G where
  coe := fun L => (L : List G).prod

instance List.ListStoGroup : CoeOut (List S) G where
  coe := fun L => L.gprod

lemma gprod_nil : ([]: List S) = (1:G ):=by {exact List.prod_nil}


lemma gprod_singleton {s:S}: ([s]:G) = s:= by
  calc
   _ = List.prod [(s:G)] := by congr
   _ = ↑s := by simp

--  simp [coe_cons, nil_eq_nil, List.prod_cons, List.prod_nil, mul_one]

lemma gprod_cons (hd : S)  (tail : List S) : (hd::tail :G) = hd * (tail :G) := by {
  simp_rw [<-List.prod_cons]
  congr
}

lemma gprod_append {l1 l2: List S} : (l1 ++ l2 : G) = (l1 :G)*( l2:G) := by {
  rw [<-List.prod_append]
  congr
  simp [List.gprod,Lean.Internal.coeM]
}

lemma gprod_append_singleton {l1 : List S} {s : S}: (l1 ++ [s] :G )= l1 * s := by {
  rw [<-gprod_singleton,gprod_append]
}

@[simp]
abbrev  inv_reverse (L : List S) : List G :=  (List.map (fun x => (x:G)⁻¹ ) L).reverse

lemma gprod_inv_eq_inv_reverse (L: List S) : (L :G)⁻¹ = inv_reverse L   := by rw [List.prod_inv_reverse]


lemma inv_reverse_prod_prod_eq_one {L: List S}  : inv_reverse L  * (L :G) = 1 := by simp [<-gprod_inv_eq_inv_reverse]

end list_properties



class OrderTwoGen {G : Type*} [Group G] (S: Set G) where
  order_two :  ∀ (x:G) , x ∈ S →  x * x = (1 :G) ∧  x ≠ (1 :G)
  expression : ∀ (x:G) , ∃ (L : List S),  x = L.gprod

namespace OrderTwoGen

variable {G : Type _} [Group G] {S: Set G} [h:OrderTwoGen S]

@[simp]
lemma gen_square_eq_one : ∀ x∈S, x * x = 1:=fun x hx => (h.order_two x hx).1

@[simp]
lemma gen_square_eq_one' (s:S): (s:G) * s = 1:= by simp [gen_square_eq_one s.1 s.2]

@[simp]
lemma inv_eq_self  [h: OrderTwoGen S]: ∀ x:G,  x∈S → x = x⁻¹ :=
fun x hx => mul_eq_one_iff_eq_inv.1 (h.order_two x hx).1

@[simp]
lemma inv_eq_self' : ∀ (x : S),  x = (x:G)⁻¹ := fun x =>  inv_eq_self x.1 x.2

-- The lemma was called non_one
lemma gen_ne_one : ∀ x∈S, x ≠ 1 :=
fun x hx => (h.order_two x hx).2

lemma gen_ne_one' : ∀ (x:S),  (x :G) ≠ 1 :=
fun x => gen_ne_one x.1 x.2


--lemma mul_generator_inv {s:S} {w:G} [orderTwoGen S]: (w*s)⁻¹ = s*w⁻¹:= by rw []

lemma inv_reverse_eq_reverse (L : List S) :  (L.reverse : List G) = inv_reverse L := by {
  simp only [coeM_reverse, inv_reverse, List.reverse_inj]
  calc
  _ = List.map (id) (L : List G) := by simp only [List.map_id]
  _ = _ := List.map_congr (fun x hx => inv_eq_self x (mem_subtype_list hx))
}

lemma reverse_prod_prod_eq_one {L: List S}  : (L.reverse :G) * L = 1:= by {
  calc
    _ =  (inv_reverse L : G) * L := by rw [<-inv_reverse_eq_reverse L]
    _ = _ := inv_reverse_prod_prod_eq_one
}

lemma gprod_reverse (L: List S) : L.reverse.gprod = (L.gprod)⁻¹ :=
 mul_eq_one_iff_eq_inv.1 reverse_prod_prod_eq_one


lemma exists_prod (g : G) : ∃ (L : List S),  g = L := h.expression g

--def AllExpression (g:G) := {L : List S| g = L}

@[simp]
def reduced_word (L : List S) := ∀ (L' : List S),  (L :G) =  L' →  L.length ≤ L'.length

end OrderTwoGen

namespace OrderTwoGen
variable {G : Type*} [Group G] (S : Set G) [OrderTwoGen S]

def length_aux (g : G) : ∃ (n:ℕ) , ∃ (L : List S), L.length = n ∧ g = L := by
  let ⟨(L : List S), hL⟩ := exists_prod g
  use L.length,L

noncomputable def length  (x : G): ℕ := Nat.find (length_aux S x)


scoped notation: max "ℓ" S " (" g ")" => (length S g)

end OrderTwoGen


section reduced_word
open OrderTwoGen

variable {G : Type*} [Group G] {S : Set G} [OrderTwoGen S]

local notation: max "ℓ(" g ")" => (length S g)

lemma length_le_list_length (L : List S) :  ℓ(L) ≤ L.length :=
  Nat.find_le (by use L)

-- The lemma was called ``inv''
lemma reverse_is_reduced (L: List S) (h: reduced_word L): reduced_word L.reverse:= by
   contrapose h
   rw [reduced_word] at *
   push_neg at *
   rcases h with ⟨LL,hL⟩
   use LL.reverse
   rw [gprod_reverse,List.length_reverse] at *
   rw [←hL.1,inv_inv]
   exact ⟨rfl,hL.2⟩

-- The lemma was called ``nil''
lemma nil_is_reduced: reduced_word ([] : List S) := by
   rintro _ _
   norm_num

-- The lemma was called singleton
lemma singleton_is_reduced {s:S}: reduced_word [s]:= by
   rintro L hL
   contrapose hL
   push_neg at *
   rw [List.length_singleton] at hL
   have : List.length L = 0:=by{linarith}
   have h1 :=List.length_eq_zero.1 this
   rw [h1,gprod_nil,gprod_singleton]
   exact gen_ne_one s.1 s.2

lemma pos_length_of_non_reduced_word (L : List S): ¬ reduced_word L → 1 ≤  L.length := by
   contrapose
   simp_rw [not_le,not_not,Nat.lt_one_iff]
   rw [List.length_eq_zero];
   intro H
   simp only [H,nil_is_reduced]

lemma length_le_iff (L: List S) : reduced_word L ↔ L.length ≤ ℓ(L.gprod):= by
   rw [length, (Nat.le_find_iff _)]
   apply Iff.intro
   .  intro h m hm
      contrapose hm
      rw [not_not] at hm
      let ⟨L', HL'⟩ := hm
      rw [not_lt,<-HL'.1]
      exact h L'  HL'.2
   .  intro H
      rw [reduced_word]
      intro L' HL'
      contrapose H
      rw [not_le] at H
      rw [not_forall]
      use L'.length
      rw [<-not_and,not_not]
      constructor
      . exact H
      . use L'

lemma length_eq_iff (L: List S) : reduced_word L ↔ L.length = ℓ(L.gprod) := by
   constructor
   . intro H
     exact ge_antisymm  (length_le_list_length  L)  ((length_le_iff  L).1 H)
   . intro H
     exact (length_le_iff  L).2 (le_of_eq H)

lemma exist_reduced_word (S : Set G) [OrderTwoGen S] (g : G) : ∃ (L: List S) , reduced_word L ∧ g = L.gprod := by
   let ⟨L',h1,h2⟩ := Nat.find_spec (@length_aux G  _ S _ g)
   use L'
   have C1 := (length_eq_iff  L').2
   rw [length] at C1
   simp_rw [h2] at h1
   exact ⟨C1 h1,h2⟩

noncomputable def choose_reduced_word (S : Set G) [OrderTwoGen S]  (g:G) : List S := Classical.choose (exist_reduced_word S g)

lemma choose_reduced_word_spec (g : G) : reduced_word (choose_reduced_word S g) ∧ g = (choose_reduced_word S g) :=
   Classical.choose_spec (exist_reduced_word S g)


def non_reduced_p  (L : List S) := fun k => ¬ reduced_word (L.take (k+1))

lemma max_reduced_word_index_aux (L: List S) (H : ¬ reduced_word L) : ∃ n, non_reduced_p  L n := by
   use L.length
   rw [non_reduced_p,List.take_all_of_le (le_of_lt (Nat.lt_succ_self L.length))]
   exact H

noncomputable def max_reduced_word_index (L : List S) (H : ¬ reduced_word L):= Nat.find (max_reduced_word_index_aux  L H)

lemma nonreduced_succ_take_max_reduced_word (L : List S) (H : ¬ reduced_word L) : ¬ reduced_word (L.take ((max_reduced_word_index  L H)+1)) := by
   let j:= max_reduced_word_index  L H
   have Hj : j = max_reduced_word_index  L H := rfl
   rw [<-Hj]
   rw [max_reduced_word_index]  at Hj
   have HH:= (Nat.find_eq_iff _).1 Hj
   rw [<-Hj,non_reduced_p] at HH
   exact HH.1

lemma reduced_take_max_reduced_word (L : List S) (H : ¬ reduced_word L) : reduced_word (L.take (max_reduced_word_index L H)) := by
   let j:= max_reduced_word_index L H
   have Hj : j = max_reduced_word_index  L H := rfl
   match j with
   | 0 =>
      rw [<-Hj,List.take_zero]
      exact nil_is_reduced
   | n+1 =>
      rw [<-Hj]
      have := (Nat.le_find_iff _ _).1 (le_of_eq Hj) n (Nat.lt_succ_self n)
      rw [non_reduced_p,not_not] at this
      exact this

lemma max_reduced_word_index_lt (L : List S) (H : ¬ reduced_word L) : max_reduced_word_index L H < L.length := by
   have Hlen := pos_length_of_non_reduced_word  L H
   rw [max_reduced_word_index, Nat.find_lt_iff _ L.length]
   use L.length -1
   rw [non_reduced_p]
   have Hlen' : 0<L.length := by linarith
   constructor
   . exact Nat.sub_lt Hlen' (by simp)
   . have : L.length -1 +1  = L.length := by rw [<-Nat.sub_add_comm Hlen,Nat.add_sub_cancel]
     rw [this,List.take_length]
     exact H

noncomputable def max_reduced_word_index' (L : List S) (H : ¬ reduced_word L) : Fin L.length:= ⟨max_reduced_word_index  L H, max_reduced_word_index_lt  L H⟩

lemma length_lt_iff_non_reduced (L : List S) : ℓ(L) < L.length ↔ ¬ reduced_word L := by {
   rw [iff_not_comm,not_lt]
   exact length_le_iff  L
}

lemma tail_reduced : reduced_word (L : List S) → reduced_word L.tail := sorry

end reduced_word