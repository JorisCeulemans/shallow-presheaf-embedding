module Types where

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Nat hiding (_⊔_)
open import Data.Nat.Properties
open import Data.Product using (Σ; Σ-syntax; proj₁; proj₂; _×_) renaming (_,_ to [_,_])
open import Data.Sum using (_⊎_) renaming (inj₁ to inl; inj₂ to inr)
open import Data.Unit using (⊤; tt)
open import Function hiding (_⟨_⟩_)
open import Level renaming (zero to lzero; suc to lsuc)
open import Relation.Binary.PropositionalEquality hiding ([_]; naturality; Extensionality)

open import Helpers
open import CwF-Structure
open import Yoneda

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

module _ {Δ Γ : Ctx ℓ} {T S : Ty Γ} (σ : Δ ⇒ Γ) where
  abstract
    ×'-natural : (T ×' S) [ σ ] ≡ (T [ σ ]) ×' (S [ σ ])
    ×'-natural = cong₃-d (MkTy _)
                         (funextI (funextI (funext λ ineq → funext λ δ → funext λ { [ t , s ] →
                           subst-× (naturality σ) [ T ⟪ ineq , func σ δ ⟫ t , S ⟪ ineq , func σ δ ⟫ s ] })))
                         (funextI (funext (λ _ → uip _ _)))
                         (funextI (funextI (funextI (funext λ _ → funext λ _ → funext λ _ → uip _ _))))

  pair-natural : (t : Tm Γ T) (s : Tm Γ S) → subst (Tm Δ) ×'-natural ((pair t s) [ σ ]') ≡ pair (t [ σ ]') (s [ σ ]')
  pair-natural t s = cong₂-d MkTm
    (term (subst (Tm Δ) ×'-natural (pair t s [ σ ]'))
        ≡⟨ sym (weak-subst-application {B = Tm Δ} (λ x y → term y) ×'-natural) ⟩
      subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z ⟨ n , δ ⟩) ×'-natural (term (pair t s [ σ ]'))
        ≡⟨ subst-∘ ×'-natural ⟩
      subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ) (cong type ×'-natural) (term (pair t s [ σ ]'))
        ≡⟨ cong (λ y → subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ) y (term (pair t s [ σ ]'))) {x = cong type ×'-natural} {y = refl} (uip _ _) ⟩
      subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ) {x = type ((T ×' S) [ σ ])} refl (term (pair (t [ σ ]') (s [ σ ]')))
        ≡⟨⟩
      term (pair (t [ σ ]') (s [ σ ]')) ∎)
    (funextI (funextI (funext λ _ → funext λ _ → uip _ _)))
    where open ≡-Reasoning

  fst-natural : (p : Tm Γ (T ×' S)) → (fst p) [ σ ]' ≡ fst (subst (Tm Δ) ×'-natural (p [ σ ]'))
  fst-natural p = cong₂-d MkTm
    (term (fst p [ σ ]')
        ≡⟨ cong (λ z → λ n δ → proj₁ (subst (λ z → (n₁ : ℕ) (γ : Δ ⟨ n₁ ⟩) → z n₁ γ) z (term (p [ σ ]')) n δ)) {x = refl} {y = cong type ×'-natural} (uip _ _) ⟩
      (λ n δ → proj₁ (subst (λ z → (n₁ : ℕ) (γ : Δ ⟨ n₁ ⟩) → z n₁ γ) (cong type ×'-natural) (term (p [ σ ]')) n δ))
        ≡⟨ cong (λ z n δ → proj₁ (z n δ)) (sym (subst-∘ {P = λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ} {f = type} ×'-natural)) ⟩
      (λ n δ → proj₁ (subst (λ z → (n₁ : ℕ) (γ : Δ ⟨ n₁ ⟩) → z ⟨ n₁ , γ ⟩) ×'-natural (term (p [ σ ]')) n δ))
        ≡⟨ cong (λ z n δ → proj₁ (z n δ)) (weak-subst-application {B = Tm Δ} (λ x y → term y) ×'-natural) ⟩
      term (fst (subst (Tm Δ) ×'-natural (p [ σ ]'))) ∎)
    (funextI (funextI (funext λ _ → funext λ _ → uip _ _)))
    where open ≡-Reasoning

  snd-natural : (p : Tm Γ (T ×' S)) → (snd p) [ σ ]' ≡ snd (subst (Tm Δ) ×'-natural (p [ σ ]'))
  snd-natural p = cong₂-d MkTm
    (term (snd p [ σ ]')
        ≡⟨ cong (λ z → λ n δ → proj₂ (subst (λ z → (n₁ : ℕ) (γ : Δ ⟨ n₁ ⟩) → z n₁ γ) z (term (p [ σ ]')) n δ)) {x = refl} {y = cong type ×'-natural} (uip _ _) ⟩
      (λ n δ → proj₂ (subst (λ z → (n₁ : ℕ) (γ : Δ ⟨ n₁ ⟩) → z n₁ γ) (cong type ×'-natural) (term (p [ σ ]')) n δ))
        ≡⟨ cong (λ z n δ → proj₂ (z n δ)) (sym (subst-∘ {P = λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ} {f = type} ×'-natural)) ⟩
      (λ n δ → proj₂ (subst (λ z → (n₁ : ℕ) (γ : Δ ⟨ n₁ ⟩) → z ⟨ n₁ , γ ⟩) ×'-natural (term (p [ σ ]')) n δ))
        ≡⟨ cong (λ z n δ → proj₂ (z n δ)) (weak-subst-application {B = Tm Δ} (λ x y → term y) ×'-natural) ⟩
      term (snd (subst (Tm Δ) ×'-natural (p [ σ ]'))) ∎)
    (funextI (funextI (funext λ _ → funext λ _ → uip _ _)))
    where open ≡-Reasoning


--------------------------------------------------
-- (Non-dependent) function types
--------------------------------------------------

record PresheafFunc {ℓ} {Γ : Ctx ℓ} (T S : Ty Γ) (n : ℕ) (γ : Γ ⟨ n ⟩) : Set ℓ where
  constructor MkFunc
  field
    _$⟨_⟩_ : ∀ {m} (ineq : m ≤ n) → T ⟨ m , Γ ⟪ ineq ⟫ γ ⟩ → S ⟨ m , Γ ⟪ ineq ⟫ γ ⟩
    naturality : ∀ {k m} (k≤m : k ≤ m) (m≤n : m ≤ n) →
                 _$⟨_⟩_ (≤-trans k≤m m≤n) ∘ subst (λ x → T ⟨ k , x γ ⟩) (sym (rel-comp Γ k≤m m≤n)) ∘ T ⟪ k≤m , Γ ⟪ m≤n ⟫ γ ⟫ ≡
                   subst (λ x → S ⟨ k , x γ ⟩) (sym (rel-comp Γ k≤m m≤n)) ∘ (S ⟪ k≤m , Γ ⟪ m≤n ⟫ γ ⟫) ∘ _$⟨_⟩_ m≤n
open PresheafFunc public

to-pshfun-eq : {Γ : Ctx ℓ} {T S : Ty Γ} {n : ℕ} {γ : Γ ⟨ n ⟩} {f g : PresheafFunc T S n γ} →
               (∀ {m} (ineq : m ≤ n) t → f $⟨ ineq ⟩ t ≡ g $⟨ ineq ⟩ t) →
               f ≡ g
to-pshfun-eq e = cong₂-d MkFunc
  (funextI (funext (λ ineq → funext λ t → e ineq t)))
  (funextI (funextI (funext λ _ → funext λ _ → uip _ _)))

lower-presheaffunc : ∀ {m n} {Γ : Ctx ℓ} {T S : Ty Γ} (ineq : m ≤ n) (γ : Γ ⟨ n ⟩) → PresheafFunc T S n γ → PresheafFunc T S m (Γ ⟪ ineq ⟫ γ)
lower-presheaffunc {m = m}{n}{Γ}{T}{S} m≤n γ f = MkFunc g g-nat
  where
    g : ∀ {k} (k≤m : k ≤ m) → T ⟨ k , Γ ⟪ k≤m ⟫ (Γ ⟪ m≤n ⟫ γ) ⟩ → S ⟨ k , Γ ⟪ k≤m ⟫ (Γ ⟪ m≤n ⟫ γ) ⟩
    g k≤m = subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ k≤m m≤n)
        ∘ f $⟨ ≤-trans k≤m m≤n ⟩_
        ∘ subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ k≤m m≤n))
    open ≡-Reasoning
    abstract
      g-nat : ∀ {k l} (k≤l : k ≤ l) (l≤m : l ≤ m) → _
      g-nat k≤l l≤m = funext λ t →
        subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
          (f $⟨ ≤-trans (≤-trans k≤l l≤m) m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ (≤-trans k≤l l≤m) m≤n))
          (subst (λ x → T ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m))
          (T ⟪ k≤l , Γ ⟪ l≤m ⟫ (Γ ⟪ m≤n ⟫ γ) ⟫ t)))
            ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
                                  (f $⟨ ≤-trans (≤-trans k≤l l≤m) m≤n ⟩ z))
                    (sym (subst-subst-sym (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n)))) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
          (f $⟨ ≤-trans (≤-trans k≤l l≤m) m≤n ⟩
          subst (λ x → T ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
          (subst (λ x → T ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (sym (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n)))
          (subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ (≤-trans k≤l l≤m) m≤n))
          (subst (λ x → T ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m))
          (T ⟪ k≤l , Γ ⟪ l≤m ⟫ (Γ ⟪ m≤n ⟫ γ) ⟫ t)))))
            ≡⟨ cong (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n))
                    (sym (weak-subst-application (λ x → f $⟨ x ⟩_) (≤-irrelevant _ _))) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
          (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
          (f $⟨ ≤-trans k≤l (≤-trans l≤m m≤n) ⟩
          subst (λ x → T ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (sym (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n)))
          (subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ (≤-trans k≤l l≤m) m≤n))
          (subst (λ x → T ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m))
          (T ⟪ k≤l , Γ ⟪ l≤m ⟫ (Γ ⟪ m≤n ⟫ γ) ⟫ t)))))
            ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
                            (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
                            (f $⟨ ≤-trans k≤l (≤-trans l≤m m≤n) ⟩ z)))
                    (sym (ctx-≤-trans-sym-assoc Γ (λ y → T ⟨ _ , y ⟩))) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
          (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
          (f $⟨ ≤-trans k≤l (≤-trans l≤m m≤n) ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n)))
          (subst (λ x → T ⟨ _ , Γ ⟪ k≤l ⟫ (x γ) ⟩) (sym (rel-comp Γ l≤m m≤n))
          (T ⟪ k≤l , Γ ⟪ l≤m ⟫ (Γ ⟪ m≤n ⟫ γ) ⟫ t))))
            ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
                            (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
                            (f $⟨ ≤-trans k≤l (≤-trans l≤m m≤n) ⟩
                            subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n))) z)))
                    (weak-subst-application (λ x → T ⟪ k≤l , x γ ⟫) (sym (rel-comp Γ l≤m m≤n))) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
          (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
          (f $⟨ ≤-trans k≤l (≤-trans l≤m m≤n) ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n)))
          (T ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t)))
            ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
                           (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
                           (z
                           (subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t))))
                    (naturality f k≤l (≤-trans l≤m m≤n)) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
          (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
          (subst (λ x → S ⟨ _ , x γ ⟩) (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n)))
          (S ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
          (f $⟨ ≤-trans l≤m m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t))))
            ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n) z)
                    (subst-∘ (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
          (subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n)))
          (subst (λ x → S ⟨ _ , x γ ⟩) (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n)))
          (S ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
          (f $⟨ ≤-trans l≤m m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t))))
            ≡⟨ subst-subst (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩)
              (trans (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n)))
                     (rel-comp Γ (≤-trans k≤l l≤m) m≤n))
          (subst (λ x → S ⟨ _ , x γ ⟩) (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n)))
          (S ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
          (f $⟨ ≤-trans l≤m m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t)))
            ≡⟨ subst-subst (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n))) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩)
              (trans (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n)))
              (trans (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n)))
                     (rel-comp Γ (≤-trans k≤l l≤m) m≤n)))
          (S ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
          (f $⟨ ≤-trans l≤m m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t))
            ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) z
                           (S ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
                           (f $⟨ ≤-trans l≤m m≤n ⟩
                           subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t)))
                    (uip _ (trans (cong (Γ ⟪ k≤l ⟫ ∘_) (rel-comp Γ l≤m m≤n))
                                  (cong (_∘ Γ ⟪ m≤n ⟫) (sym (rel-comp Γ k≤l l≤m))))) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩)
              (trans (cong (Γ ⟪ k≤l ⟫ ∘_) (rel-comp Γ l≤m m≤n))
                     (cong (_∘ Γ ⟪ m≤n ⟫) (sym (rel-comp Γ k≤l l≤m))))
          (S ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
          (f $⟨ ≤-trans l≤m m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t))
            ≡⟨ sym (subst-subst (cong (Γ ⟪ k≤l ⟫ ∘_) (rel-comp Γ l≤m m≤n))) ⟩
        subst (λ x → S ⟨ _ , x γ ⟩) (cong (_∘ Γ ⟪ m≤n ⟫) (sym (rel-comp Γ k≤l l≤m)))
          (subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪ k≤l ⟫ ∘_) (rel-comp Γ l≤m m≤n))
          (S ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
          (f $⟨ ≤-trans l≤m m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t)))
            ≡⟨ sym (subst-∘ (sym (rel-comp Γ k≤l l≤m))) ⟩
        subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m))
          (subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪ k≤l ⟫ ∘_) (rel-comp Γ l≤m m≤n))
          (S ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
          (f $⟨ ≤-trans l≤m m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t)))
            ≡⟨ cong (subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m)))
                    (sym (subst-∘ (rel-comp Γ l≤m m≤n))) ⟩
        subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m))
          (subst (λ x → S ⟨ _ , Γ ⟪ k≤l ⟫ (x γ) ⟩) (rel-comp Γ l≤m m≤n)
          (S ⟪ k≤l , Γ ⟪ ≤-trans l≤m m≤n ⟫ γ ⟫
          (f $⟨ ≤-trans l≤m m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t)))
            ≡⟨ cong (subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m)))
                    (weak-subst-application (λ x → S ⟪ k≤l , x γ ⟫) (rel-comp Γ l≤m m≤n)) ⟩
        subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m))
          (S ⟪ k≤l , Γ ⟪ l≤m ⟫ (Γ ⟪ m≤n ⟫ γ) ⟫
          subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ l≤m m≤n)
          (f $⟨ ≤-trans l≤m m≤n ⟩
          subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ l≤m m≤n)) t)) ∎

_⇛_ : {Γ : Ctx ℓ} → Ty Γ → Ty Γ → Ty Γ
type (_⇛_ {Γ = Γ} T S) = λ n γ → PresheafFunc T S n γ
morph (_⇛_ {Γ = Γ} T S) = lower-presheaffunc
morph-id (_⇛_ {Γ = Γ} T S) = λ γ → funext λ f → to-pshfun-eq λ m≤n t →
  subst (λ x → (T ⇛ S) ⟨ _ , x γ ⟩) (rel-id Γ) ((T ⇛ S) ⟪ ≤-refl , γ ⟫ f) $⟨ m≤n ⟩ t
      ≡⟨ cong (λ z → z t) (sym (weak-subst-application {B = λ x → (T ⇛ S) ⟨ _ , x γ ⟩} (λ x y → y $⟨ m≤n ⟩_) (rel-id Γ))) ⟩
  subst (λ x → T ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩ → S ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩) (rel-id Γ) (((T ⇛ S) ⟪ ≤-refl , γ ⟫ f) $⟨ m≤n ⟩_) t
      ≡⟨ function-subst (rel-id Γ) (((T ⇛ S) ⟪ ≤-refl , γ ⟫ f) $⟨ m≤n ⟩_) ⟩
  subst (λ x → S ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩) (rel-id Γ)
    (((T ⇛ S) ⟪ ≤-refl , γ ⟫ f) $⟨ m≤n ⟩
    (subst (λ x → T ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩) (sym (rel-id Γ)) t))
      ≡⟨⟩
  subst (λ x → S ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩) (rel-id Γ)
    (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ m≤n ≤-refl)
    (f $⟨ ≤-trans m≤n ≤-refl ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ m≤n ≤-refl))
    (subst (λ x → T ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩) (sym (rel-id Γ)) t)))
      ≡⟨ subst-∘ (rel-id Γ) ⟩
  subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪ m≤n ⟫ ∘_) (rel-id Γ))
    (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ m≤n ≤-refl)
    (f $⟨ ≤-trans m≤n ≤-refl ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ m≤n ≤-refl))
    (subst (λ x → T ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩) (sym (rel-id Γ)) t)))
      ≡⟨ subst-subst (rel-comp Γ m≤n ≤-refl) ⟩
  subst (λ x → S ⟨ _ , x γ ⟩) (trans (rel-comp Γ m≤n ≤-refl) (cong (Γ ⟪ m≤n ⟫ ∘_) (rel-id Γ)))
    (f $⟨ ≤-trans m≤n ≤-refl ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ m≤n ≤-refl))
    (subst (λ x → T ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩) (sym (rel-id Γ)) t))
      ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) z
                      (f $⟨ ≤-trans m≤n ≤-refl ⟩
                      subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ m≤n ≤-refl))
                      (subst (λ x → T ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩) (sym (rel-id Γ)) t)))
              (uip _ (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))) ⟩
  subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))
    (f $⟨ ≤-trans m≤n ≤-refl ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ m≤n ≤-refl))
    (subst (λ x → T ⟨ _ , Γ ⟪ m≤n ⟫ (x γ) ⟩) (sym (rel-id Γ)) t))
      ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))
                      (f $⟨ ≤-trans m≤n ≤-refl ⟩
                      subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ m≤n ≤-refl)) z))
              (subst-∘ (sym (rel-id Γ))) ⟩
  subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))
    (f $⟨ ≤-trans m≤n ≤-refl ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ m≤n ≤-refl))
    (subst (λ x → T ⟨ _ , x γ ⟩) (cong (Γ ⟪ m≤n ⟫ ∘_) (sym (rel-id Γ))) t))
      ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))
                      (f $⟨ ≤-trans m≤n ≤-refl ⟩ z))
              (subst-subst (cong (Γ ⟪ m≤n ⟫ ∘_) (sym (rel-id Γ)))) ⟩
  subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))
    (f $⟨ ≤-trans m≤n ≤-refl ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (trans (cong (Γ ⟪ m≤n ⟫ ∘_) (sym (rel-id Γ))) (sym (rel-comp Γ m≤n ≤-refl))) t)
      ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))
                      (f $⟨ ≤-trans m≤n ≤-refl ⟩
                      subst (λ x → T ⟨ _ , x γ ⟩) z t))
              (uip _ (cong (Γ ⟪_⟫) (sym (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)))) ⟩
  subst (λ x → S ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))
    (f $⟨ ≤-trans m≤n ≤-refl ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (sym (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))) t)
      ≡⟨ sym (subst-∘ (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)) ⟩
  subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)
    (f $⟨ ≤-trans m≤n ≤-refl ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (cong (Γ ⟪_⟫) (sym (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n))) t)
      ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)
                     (f $⟨ ≤-trans m≤n ≤-refl ⟩ z))
              (sym (subst-∘ (sym (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)))) ⟩
  subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)
    (f $⟨ ≤-trans m≤n ≤-refl ⟩
    subst (λ x → T ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (sym (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)) t)
      ≡⟨ weak-subst-application (λ x → f $⟨ x ⟩_) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n) ⟩
  f $⟨ m≤n ⟩
    subst (λ x → T ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)
    (subst (λ x → T ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (sym (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)) t)
      ≡⟨ cong (f $⟨ m≤n ⟩_) (subst-subst-sym (≤-irrelevant (≤-trans m≤n ≤-refl) m≤n)) ⟩
  f $⟨ m≤n ⟩ t ∎
  where open ≡-Reasoning
morph-comp (_⇛_ {Γ = Γ} T S) = λ l≤m m≤n γ → funext λ f → to-pshfun-eq λ k≤l t →
  (subst (λ x → (T ⇛ S) ⟨ _ , x γ ⟩) (rel-comp Γ l≤m m≤n) ((T ⇛ S) ⟪ ≤-trans l≤m m≤n , γ ⟫ f)) $⟨ k≤l ⟩ t
      ≡⟨ cong (λ z → z t) (sym (weak-subst-application {B = λ x → (T ⇛ S) ⟨ _ , x γ ⟩} (λ x y → y $⟨ k≤l ⟩_) (rel-comp Γ l≤m m≤n))) ⟩
  subst (λ x → T ⟨ _ , Γ ⟪ k≤l ⟫ (x γ) ⟩ → S ⟨ _ , Γ ⟪ k≤l ⟫ (x γ) ⟩) (rel-comp Γ l≤m m≤n) (((T ⇛ S) ⟪ ≤-trans l≤m m≤n , γ ⟫ f) $⟨ k≤l ⟩_) t
      ≡⟨ function-subst (rel-comp Γ l≤m m≤n) (((T ⇛ S) ⟪ ≤-trans l≤m m≤n , γ ⟫ f) $⟨ k≤l ⟩_) ⟩
  subst (λ x → S ⟨ _ , Γ ⟪ k≤l ⟫ (x γ) ⟩) (rel-comp Γ l≤m m≤n)
    (((T ⇛ S) ⟪ ≤-trans l≤m m≤n , γ ⟫ f) $⟨ k≤l ⟩
    (subst (λ x → T ⟨ _ , Γ ⟪ k≤l ⟫ (x γ) ⟩) (sym (rel-comp Γ l≤m m≤n)) t))
      ≡⟨⟩
  subst (λ x → S ⟨ _ , Γ ⟪ k≤l ⟫ (x γ) ⟩) (rel-comp Γ l≤m m≤n)
    (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ k≤l (≤-trans l≤m m≤n))
    (f $⟨ ≤-trans k≤l (≤-trans l≤m m≤n) ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n)))
    (subst (λ x → T ⟨ _ , Γ ⟪ k≤l ⟫ (x γ) ⟩) (sym (rel-comp Γ l≤m m≤n)) t)))
      ≡⟨ ctx-≤-trans-assoc Γ (λ y → S ⟨ _ , y ⟩) ⟩
  subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (rel-comp Γ k≤l l≤m)
    (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
    (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
    (f $⟨ ≤-trans k≤l (≤-trans l≤m m≤n) ⟩
    subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ k≤l (≤-trans l≤m m≤n)))
    (subst (λ x → T ⟨ _ , Γ ⟪ k≤l ⟫ (x γ) ⟩) (sym (rel-comp Γ l≤m m≤n)) t))))
      ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (rel-comp Γ k≤l l≤m)
                      (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
                      (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
                      (f $⟨ ≤-trans k≤l (≤-trans l≤m m≤n) ⟩ z))))
             (ctx-≤-trans-sym-assoc Γ (λ y → T ⟨ _ , y ⟩)) ⟩
  subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (rel-comp Γ k≤l l≤m)
    (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
    (subst (λ x → S ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
    (f $⟨ ≤-trans k≤l (≤-trans l≤m m≤n) ⟩
    subst (λ x → T ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (sym (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n)))
    (subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ (≤-trans k≤l l≤m) m≤n))
    (subst (λ x → T ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m)) t)))))
      ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (rel-comp Γ k≤l l≤m)
                     (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n) z))
              (weak-subst-application (λ x → f $⟨ x ⟩_) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))) ⟩
  subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (rel-comp Γ k≤l l≤m)
    (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
    (f $⟨ ≤-trans (≤-trans k≤l l≤m) m≤n ⟩
    subst (λ x → T ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))
    (subst (λ x → T ⟨ _ , Γ ⟪ x ⟫ γ ⟩) (sym (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n)))
    (subst (λ x → T ⟨ _ , x γ ⟩) (sym (rel-comp Γ (≤-trans k≤l l≤m) m≤n))
    (subst (λ x → T ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (sym (rel-comp Γ k≤l l≤m)) t)))))
      ≡⟨ cong (λ z → subst (λ x → S ⟨ _ , x (Γ ⟪ m≤n ⟫ γ) ⟩) (rel-comp Γ k≤l l≤m)
                     (subst (λ x → S ⟨ _ , x γ ⟩) (rel-comp Γ (≤-trans k≤l l≤m) m≤n)
                     (f $⟨ ≤-trans (≤-trans k≤l l≤m) m≤n ⟩ z)))
              (subst-subst-sym (≤-irrelevant (≤-trans k≤l (≤-trans l≤m m≤n)) (≤-trans (≤-trans k≤l l≤m) m≤n))) ⟩
  ((T ⇛ S) ⟪ l≤m , Γ ⟪ m≤n ⟫ γ ⟫) ((T ⇛ S) ⟪ m≤n , γ ⟫ f) $⟨ k≤l ⟩ t ∎
  where open ≡-Reasoning
{-
_⇛_ : {Γ : Ctx ℓ} → Ty Γ → Ty Γ → Ty Γ
type (T ⇛ S) = λ n γ → Tm (𝕪 n ,, (T [ to-𝕪⇒* γ ])) (S [ to-𝕪⇒* γ ⊚ π ])
morph (_⇛_ {Γ = Γ} T S) = λ m≤n γ s → helper (s [ (to-𝕪⇒𝕪 m≤n) ⊹ ]')
  where
    helper : ∀ {m n} {m≤n : m ≤ n} {γ : Γ ⟨ n ⟩} →
             Tm (𝕪 m ,, (T [ to-𝕪⇒* γ ] [ to-𝕪⇒𝕪 m≤n ])) (S [ to-𝕪⇒* γ ⊚ π ] [ (to-𝕪⇒𝕪 m≤n) ⊹ ]) →
             Tm (𝕪 m ,, (T [ to-𝕪⇒* (Γ ⟪ m≤n ⟫ γ) ])) (S [ to-𝕪⇒* (Γ ⟪ m≤n ⟫ γ) ⊚ π ])
    helper {m} {n} {m≤n} {γ} = subst (λ x → Tm (𝕪 m ,, T [ x ]) (S [ x ⊚ π ])) (𝕪-comp m≤n γ) ∘
                               subst (λ x → Tm (𝕪 m ,, x) (S [ to-𝕪⇒* γ ⊚ to-𝕪⇒𝕪 m≤n ⊚ π {T = x}])) (ty-subst-comp T (to-𝕪⇒* γ) (to-𝕪⇒𝕪 m≤n)) ∘
                               subst (λ x → Tm (𝕪 m ,, T [ to-𝕪⇒* γ ] [ to-𝕪⇒𝕪 m≤n ]) (S [ x ])) (sym (⊚-assoc (to-𝕪⇒* γ) (to-𝕪⇒𝕪 m≤n) π)) ∘
                               subst (λ x → Tm (𝕪 m ,, T [ to-𝕪⇒* γ ] [ to-𝕪⇒𝕪 m≤n ]) (S [ to-𝕪⇒* γ ⊚ x ])) (⊹-π-comm (to-𝕪⇒𝕪 m≤n)) ∘
                               subst (λ x → Tm (𝕪 m ,, T [ to-𝕪⇒* γ ] [ to-𝕪⇒𝕪 m≤n ]) (S [ x ])) (⊚-assoc (to-𝕪⇒* γ) π ((to-𝕪⇒𝕪 m≤n) ⊹)) ∘
                               subst (λ x → Tm (𝕪 m ,, T [ to-𝕪⇒* γ ] [ to-𝕪⇒𝕪 m≤n ]) x) (ty-subst-comp S (to-𝕪⇒* γ ⊚ π) ((to-𝕪⇒𝕪 m≤n) ⊹))
morph-id (T ⇛ S) = {!!}
morph-comp (T ⇛ S) = {!!}

module _ {Γ : Ctx ℓ} {T S : Ty Γ} where
  lam : Tm (Γ ,, T) (S [ π ]) → Tm Γ (T ⇛ S)
  term (lam b) = λ n γ → subst (λ x → Tm (𝕪 n ,, T [ to-𝕪⇒* γ ]) (S [ x ])) (⊹-π-comm (to-𝕪⇒* γ))
                                (subst (λ x → Tm (𝕪 n ,, T [ to-𝕪⇒* γ ]) x) (ty-subst-comp S π (to-𝕪⇒* γ ⊹))
                                       (b [ to-𝕪⇒* γ ⊹ ]'))
  naturality (lam b) = {!!}

  ap : Tm Γ (T ⇛ S) → Tm (Γ ,, T) (S [ π ])
  term (ap f) = λ n γ → {!term f!}
  naturality (ap f) = {!!}

  app : Tm Γ (T ⇛ S) → Tm Γ T → Tm Γ S
  app f t = {!ap f [ ? ]'!}
-}

--------------------------------------------------
-- Sum types
--------------------------------------------------

subst-⊎ˡ : ∀ {a b c} {A : Set a} {B : A → Set b} {C : A → Set c}
           {x x' : A} (e : x ≡ x') {y : B x} →
           subst (λ x → B x ⊎ C x) e (inl y) ≡ inl (subst B e y)
subst-⊎ˡ e = weak-subst-application (λ _ w → inl w) e

subst-⊎ʳ : ∀ {a b c} {A : Set a} {B : A → Set b} {C : A → Set c}
           {x x' : A} (e : x ≡ x') {z : C x} →
           subst (λ x → B x ⊎ C x) e (inr z) ≡ inr (subst C e z)
subst-⊎ʳ e = weak-subst-application (λ _ w → inr w) e

_⊎'_ : {Γ : Ctx ℓ} → Ty Γ → Ty Γ → Ty Γ
_⊎'_ {Γ = Γ} T S = MkTy (λ n γ → T ⟨ n , γ ⟩ ⊎ S ⟨ n , γ ⟩)
                         (λ { ineq γ (inl t) → inl (T ⟪ ineq , γ ⟫ t) ; ineq γ (inr s) → inr (S ⟪ ineq , γ ⟫ s) })
                         (λ γ → funext λ { (inl t) → trans (subst-⊎ˡ _) (cong inl (cong-app (morph-id T γ) t))
                                          ; (inr s) → trans (subst-⊎ʳ _) (cong inr (cong-app (morph-id S γ) s)) })
                         (λ k≤m m≤n γ → funext λ { (inl t) → trans (subst-⊎ˡ _) (cong inl (cong-app (morph-comp T k≤m m≤n γ) t))
                                                  ; (inr s) → trans (subst-⊎ʳ _) (cong inr (cong-app (morph-comp S k≤m m≤n γ) s)) })
{-
type (T ⊎' S) = λ n γ → T ⟨ n , γ ⟩ ⊎ S ⟨ n , γ ⟩
morph (T ⊎' S) = λ { ineq γ (inl t) → inl (T ⟪ ineq , γ ⟫ t) ; ineq γ (inr s) → inr (S ⟪ ineq , γ ⟫ s) }
morph-id (T ⊎' S) = λ γ → funext λ { (inl t) → {!trans ? ?!} ; (inr s) → {!!} }
morph-comp (T ⊎' S) = {!!}
-}

module _ {Γ : Ctx ℓ} {T S : Ty Γ} where
  inl' : Tm Γ T → Tm Γ (T ⊎' S)
  term (inl' t) = λ n γ → inl (t ⟨ n , γ ⟩')
  naturality (inl' t) = λ ineq γ → cong inl (t ⟪ ineq , γ ⟫')

  inr' : Tm Γ S → Tm Γ (T ⊎' S)
  term (inr' s) = λ n γ → inr (s ⟨ n , γ ⟩')
  naturality (inr' s) = λ ineq γ → cong inr (s ⟪ ineq , γ ⟫')

inl'⟨_⟩_ : {Γ : Ctx ℓ} {T : Ty Γ} (S : Ty Γ) (t : Tm Γ T) → Tm Γ (T ⊎' S)
inl'⟨ S ⟩ t = inl' {S = S} t

inr'⟨_⟩_ : {Γ : Ctx ℓ} (T : Ty Γ) {S : Ty Γ} (s : Tm Γ S) → Tm Γ (T ⊎' S)
inr'⟨ T ⟩ s = inr' {T = T} s

module _ {Δ Γ : Ctx ℓ} {T S : Ty Γ} (σ : Δ ⇒ Γ) where
  abstract
    ⊎'-natural : (T ⊎' S) [ σ ] ≡ (T [ σ ]) ⊎' (S [ σ ])
    ⊎'-natural = cong₃-d (MkTy _)
                          (funextI (funextI (funext λ ineq → funext λ δ → funext λ {
                            (inl t) → subst-⊎ˡ (naturality σ) ;
                            (inr s) → subst-⊎ʳ (naturality σ) })))
                          (funextI (funext (λ _ → uip _ _)))
                          (funextI (funextI (funextI (funext λ _ → funext λ _ → funext λ _ → uip _ _))))

  inl'-natural : (t : Tm Γ T) → subst (Tm Δ) ⊎'-natural ((inl' t) [ σ ]') ≡ inl' (t [ σ ]')
  inl'-natural t = cong₂-d MkTm
    (term (subst (Tm Δ) ⊎'-natural (inl' t [ σ ]'))
        ≡⟨ sym (weak-subst-application {B = Tm Δ} (λ x y → term y) ⊎'-natural) ⟩
      subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z ⟨ n , δ ⟩) ⊎'-natural (term (inl'⟨ S [ σ ] ⟩ (t [ σ ]')))
        ≡⟨ subst-∘ ⊎'-natural ⟩
      subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ) (cong type ⊎'-natural) (term (inl'⟨ S [ σ ] ⟩ (t [ σ ]')))
        ≡⟨ cong (λ y → subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ) y (term (inl'⟨ S [ σ ] ⟩ (t [ σ ]')))) {x = cong type ⊎'-natural} {y = refl} (uip _ _) ⟩
      subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ) {x = type ((T ⊎' S) [ σ ])} refl (term (inl'⟨ S [ σ ] ⟩ (t [ σ ]')))
        ≡⟨⟩
      term (inl'⟨ S [ σ ] ⟩ (t [ σ ]')) ∎)
    (funextI (funextI (funext λ _ → funext λ _ → uip _ _)))
    where open ≡-Reasoning

  inr'-natural : (s : Tm Γ S) → subst (Tm Δ) ⊎'-natural ((inr' s) [ σ ]') ≡ inr' (s [ σ ]')
  inr'-natural s = cong₂-d MkTm
    (term (subst (Tm Δ) ⊎'-natural (inr' s [ σ ]'))
        ≡⟨ sym (weak-subst-application {B = Tm Δ} (λ x y → term y) ⊎'-natural) ⟩
      subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z ⟨ n , δ ⟩) ⊎'-natural (term (inr'⟨ T [ σ ] ⟩ (s [ σ ]')))
        ≡⟨ subst-∘ ⊎'-natural ⟩
      subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ) (cong type ⊎'-natural) (term (inr'⟨ T [ σ ] ⟩ (s [ σ ]')))
        ≡⟨ cong (λ y → subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ) y (term (inr'⟨ T [ σ ] ⟩ (s [ σ ]')))) {x = cong type ⊎'-natural} {y = refl} (uip _ _) ⟩
      subst (λ z → (n : ℕ) (δ : Δ ⟨ n ⟩) → z n δ) {x = type ((T ⊎' S) [ σ ])} refl (term (inr'⟨ T [ σ ] ⟩ (s [ σ ]')))
        ≡⟨⟩
      term (inr'⟨ T [ σ ] ⟩ (s [ σ ]')) ∎)
    (funextI (funextI (funext λ _ → funext λ _ → uip _ _)))
    where open ≡-Reasoning


--------------------------------------------------
-- Discrete types
--------------------------------------------------

Discr : (A : Set ℓ) → Ty ◇
type (Discr A) = λ _ _ → A
morph (Discr A) = λ _ _ → id
morph-id (Discr A) = λ _ → refl
morph-comp (Discr A) = λ _ _ _ → refl

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
                          (funextI (funextI (funext λ ineq → funext λ _ → uip _ _)))

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
