--------------------------------------------------
-- (Non-dependent) product types
--------------------------------------------------

open import Categories

module Types.Products {C : Category} where

open import Data.Product using (Σ; Σ-syntax; proj₁; proj₂; _×_) renaming (_,_ to [_,_])
open import Function using (id)
open import Relation.Binary.PropositionalEquality hiding ([_]; naturality)

open import Helpers
open import CwF-Structure.Contexts
open import CwF-Structure.Types
open import CwF-Structure.Terms

private
  variable
    Γ Δ : Ctx C
    T T' S S' : Ty Γ


_⊠_ : Ty Γ → Ty Γ → Ty Γ
T ⊠ S ⟨ x , γ ⟩ = T ⟨ x , γ ⟩ × S ⟨ x , γ ⟩
T ⊠ S ⟪ f , eγ ⟫ [ t , s ] = [ T ⟪ f , eγ ⟫ t , S ⟪ f , eγ ⟫ s ]
ty-cong (T ⊠ S) e = cong₂ [_,_] (ty-cong T e) (ty-cong S e)
ty-id (T ⊠ S) = cong₂ [_,_] (ty-id T) (ty-id S)
ty-comp (T ⊠ S) = cong₂ [_,_] (ty-comp T) (ty-comp S)

⊠-bimap : (T ↣ T') → (S ↣ S') → (T ⊠ S ↣ T' ⊠ S')
func (⊠-bimap η φ) [ t , s ] = [ func η t , func φ s ]
naturality (⊠-bimap η φ) = cong₂ [_,_] (naturality η) (naturality φ)

⊠-cong : T ≅ᵗʸ T' → S ≅ᵗʸ S' → T ⊠ S ≅ᵗʸ T' ⊠ S'
from (⊠-cong T=T' S=S') = ⊠-bimap (from T=T') (from S=S')
to (⊠-cong T=T' S=S') = ⊠-bimap (to T=T') (to S=S')
eq (isoˡ (⊠-cong T=T' S=S')) [ t , s ] = cong₂ [_,_] (eq (isoˡ T=T') t) (eq (isoˡ S=S') s)
eq (isoʳ (⊠-cong T=T' S=S')) [ t , s ] = cong₂ [_,_] (eq (isoʳ T=T') t) (eq (isoʳ S=S') s)

pair : Tm Γ T → Tm Γ S → Tm Γ (T ⊠ S)
pair t s ⟨ x , γ ⟩' = [ t ⟨ x , γ ⟩' , s ⟨ x , γ ⟩' ]
naturality (pair t s) f eγ = cong₂ [_,_] (naturality t f eγ) (naturality s f eγ)

fst : Tm Γ (T ⊠ S) → Tm Γ T
fst p ⟨ x , γ ⟩' = proj₁ (p ⟨ x , γ ⟩')
naturality (fst p) f eγ = cong proj₁ (naturality p f eγ)

snd : Tm Γ (T ⊠ S) → Tm Γ S
snd p ⟨ x , γ ⟩' = proj₂ (p ⟨ x , γ ⟩')
naturality (snd p) f eγ = cong proj₂ (naturality p f eγ)

pair-cong : {t t' : Tm Γ T} {s s' : Tm Γ S} → t ≅ᵗᵐ t' → s ≅ᵗᵐ s' → pair t s ≅ᵗᵐ pair t' s'
eq (pair-cong t=t' s=s') γ = cong₂ [_,_] (eq t=t' γ) (eq s=s' γ)

fst-cong : {p p' : Tm Γ (T ⊠ S)} → p ≅ᵗᵐ p' → fst p ≅ᵗᵐ fst p'
eq (fst-cong p=p') γ = cong proj₁ (eq p=p' γ)

snd-cong : {p p' : Tm Γ (T ⊠ S)} → p ≅ᵗᵐ p' → snd p ≅ᵗᵐ snd p'
eq (snd-cong p=p') γ = cong proj₂ (eq p=p' γ)

module _
  {T : Ty Γ} {T' : Ty Γ} {S : Ty Γ} {S' : Ty Γ}
  (T=T' : T ≅ᵗʸ T') (S=S' : S ≅ᵗʸ S')
  where
  pair-ι : (t : Tm Γ T') (s : Tm Γ S') → ι[ ⊠-cong T=T' S=S' ] pair t s ≅ᵗᵐ pair (ι[ T=T' ] t) (ι[ S=S' ] s)
  eq (pair-ι t s) _ = refl

  fst-ι : (p : Tm Γ (T' ⊠ S')) → ι[ T=T' ] fst p ≅ᵗᵐ fst (ι[ ⊠-cong T=T' S=S' ] p)
  eq (fst-ι p) _ = refl

  snd-ι : (p : Tm Γ (T' ⊠ S')) → ι[ S=S' ] snd p ≅ᵗᵐ snd (ι[ ⊠-cong T=T' S=S' ] p)
  eq (snd-ι p) _ = refl

module _ {T : Ty Γ} {S : Ty Γ} (σ : Δ ⇒ Γ) where
  ⊠-natural : (T ⊠ S) [ σ ] ≅ᵗʸ (T [ σ ]) ⊠ (S [ σ ])
  func (from ⊠-natural) = id
  naturality (from ⊠-natural) = refl
  func (to ⊠-natural) = id
  naturality (to ⊠-natural) = refl
  eq (isoˡ ⊠-natural) _ = refl
  eq (isoʳ ⊠-natural) _ = refl

  pair-natural : (t : Tm Γ T) (s : Tm Γ S) → (pair t s) [ σ ]' ≅ᵗᵐ ι[ ⊠-natural ] (pair (t [ σ ]') (s [ σ ]'))
  eq (pair-natural t s) _ = refl

  fst-natural : (p : Tm Γ (T ⊠ S)) → (fst p) [ σ ]' ≅ᵗᵐ fst (ι⁻¹[ ⊠-natural ] (p [ σ ]'))
  eq (fst-natural p) _ = refl

  snd-natural : (p : Tm Γ (T ⊠ S)) → (snd p) [ σ ]' ≅ᵗᵐ snd (ι⁻¹[ ⊠-natural ] (p [ σ ]'))
  eq (snd-natural p) _ = refl

module _ (t : Tm Γ T) (s : Tm Γ S) where
  β-⊠-fst : fst (pair t s) ≅ᵗᵐ t
  eq β-⊠-fst _ = refl

  β-⊠-snd : snd (pair t s) ≅ᵗᵐ s
  eq β-⊠-snd _ = refl

η-⊠ : (p : Tm Γ (T ⊠ S)) →
      p ≅ᵗᵐ pair (fst p) (snd p)
eq (η-⊠ p) _ = refl
