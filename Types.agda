module Types where

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Product using (proj₁; proj₂; _×_) renaming (_,_ to [_,_])
open import Data.Sum using (_⊎_) renaming (inj₁ to inl; inj₂ to inr)
open import Relation.Binary.PropositionalEquality hiding ([_]; naturality; Extensionality)

open import Helpers
open import CwF-Structure

--------------------------------------------------
-- (Non-dependent) product types
--------------------------------------------------

subst-× : ∀ {a b c} {A : Set a} {B : A → Set b} {C : A → Set c}
          {x x' : A} (e : x ≡ x')
          (p : B x × C x) →
          subst (λ x → B x × C x) e p ≡ [ subst B e (proj₁ p) , subst C e (proj₂ p) ]
subst-× refl p = refl

_×'_ : {Γ : Ctx ℓ} → Ty Γ → Ty Γ → Ty Γ
_×'_ {Γ = Γ} T S = MkTy (λ n γ → T ⟨ n , γ ⟩ × S ⟨ n , γ ⟩)
                   (λ { ineq γ [ t , s ] → [ T ⟪ ineq , γ ⟫ t , S ⟪ ineq , γ ⟫ s ] })
                   (λ γ → funext λ { [ t , s ] → trans (subst-× (rel-id Γ) _)
                                                            (cong₂ [_,_] (cong-app (morph-id T γ) t)
                                                                         (cong-app (morph-id S γ) s)) })
                   (λ k≤m m≤n γ → funext λ { [ t , s ] → trans (subst-× (rel-comp Γ k≤m m≤n) _)
                                                                 (cong₂ [_,_] (cong-app (morph-comp T k≤m m≤n γ) t)
                                                                              (cong-app (morph-comp S k≤m m≤n γ) s)) })
{-
module _ {Γ : Ctx ℓ} {T S : Ty Γ} where
  pair : Tm Γ T → Tm Γ S → Tm Γ (T ×' S)
  term (pair t s) = λ n γ → [ t ⟨ n , γ ⟩' , s ⟨ n , γ ⟩' ]
  naturality (pair t s) = λ ineq γ → cong₂ [_,_] (t ⟪ ineq , γ ⟫') (s ⟪ ineq , γ ⟫')

  fst : Tm Γ (T ×' S) → Tm Γ T
  term (fst p) = λ n γ → proj₁ (p ⟨ n , γ ⟩')
  naturality (fst p) = λ ineq γ →
    T ⟪ ineq , γ ⟫ ((fst p) ⟨ _ , γ ⟩') ≡⟨ cong proj₁ (p ⟪ _ , γ ⟫') ⟩
    fst p ⟨ _ , Γ ⟪ ineq ⟫ γ ⟩' ∎
    where open ≡-Reasoning

  snd : Tm Γ (T ×' S) → Tm Γ S
  term (snd p) = λ n γ → proj₂ (p ⟨ n , γ ⟩')
  naturality (snd p) = λ ineq γ → cong proj₂ (p ⟪ _ , γ ⟫')

--------------------------------------------------
-- Sum types
--------------------------------------------------

_⊎'_ : {Γ : Ctx ℓ} → Ty Γ → Ty Γ → Ty Γ
type (T ⊎' S) = λ n γ → T ⟨ n , γ ⟩ ⊎ S ⟨ n , γ ⟩
morph (T ⊎' S) = λ { ineq γ (inl t) → inl (T ⟪ ineq , γ ⟫ t) ; ineq γ (inr s) → inr (S ⟪ ineq , γ ⟫ s) }

module _ {Γ : Ctx ℓ} {T S : Ty Γ} where
  inl' : Tm Γ T → Tm Γ (T ⊎' S)
  term (inl' t) = λ n γ → inl (t ⟨ n , γ ⟩')
  naturality (inl' t) = λ ineq γ → cong inl (t ⟪ ineq , γ ⟫')

  inr' : Tm Γ S → Tm Γ (T ⊎' S)
  term (inr' s) = λ n γ → inr (s ⟨ n , γ ⟩')
  naturality (inr' s) = λ ineq γ → cong inr (s ⟪ ineq , γ ⟫')


--------------------------------------------------
-- Discrete types
--------------------------------------------------

Discr : (A : Set ℓ) → Ty ◇
type (Discr A) = λ _ _ → A
morph (Discr A) = λ _ _ → id

discr : {A : Set ℓ} → A → Tm ◇ (Discr A)
term (discr a) = λ _ _ → a
naturality (discr a) = λ _ _ → refl

undiscr : {A : Set ℓ} → Tm ◇ (Discr A) → A
undiscr t = t ⟨ 0 , lift tt ⟩'

undiscr-discr : {A : Set ℓ} (a : A) → undiscr (discr a) ≡ a
undiscr-discr a = refl

discr-undiscr : {A : Set ℓ} (t : Tm ◇ (Discr A)) → discr (undiscr t) ≡ t
discr-undiscr t = cong₂-d MkTm
                          (sym (funext λ n → funext λ γ → t ⟪ z≤n , lift tt ⟫'))
                          (funextI (funextI (funext λ ineq → funext λ _ → uip)))

Unit' : Ty ◇
Unit' = Discr ⊤

tt' : Tm ◇ Unit'
tt' = discr tt

Bool' : Ty ◇
Bool' = Discr Bool

true' : Tm ◇ Bool'
true' = discr true

false' : Tm ◇ Bool'
false' = discr false

if'_then'_else'_ : {Γ : Ctx 0ℓ} {T : Ty Γ} → Tm Γ (Bool' [ empty-subst Γ ]) → Tm Γ T → Tm Γ T → Tm Γ T
term (if' c then' t else' f) = λ n γ → if c ⟨ n , γ ⟩' then t ⟨ n , γ ⟩' else f ⟨ n , γ ⟩'
naturality (if'_then'_else'_ {Γ = Γ} c t f) {m} {n} ineq γ with c ⟨ m , Γ ⟪ ineq ⟫ γ ⟩' | c ⟨ n , γ ⟩' | c ⟪ ineq , γ ⟫'
naturality (if'_then'_else'_ {Γ} c t f) {m} {n} ineq γ | false | .false | refl = f ⟪ ineq , γ ⟫'
naturality (if'_then'_else'_ {Γ} c t f) {m} {n} ineq γ | true  | .true  | refl = t ⟪ ineq , γ ⟫'

Nat' : Ty ◇
Nat' = Discr ℕ

zero' : Tm ◇ Nat'
zero' = discr zero

suc' : Tm ◇ Nat' → Tm ◇ Nat'
suc' t = discr (suc (undiscr t))
-}