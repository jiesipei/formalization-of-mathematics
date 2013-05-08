Require Import ssreflect ssrbool eqtype ssrnat ssrfun.
Require Import seq tuple choice.
Require Import finalg finfun fingroup finset fintype.
Require Import bigop matrix ssralg.
Require Import mxpoly poly polydiv.
Require Import div zmodp.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensives.

Import GRing.Theory Pdiv.Ring Pdiv.CommonRing Pdiv.RingMonic.
Open Scope ring_scope.

Section missingLemmas.
Lemma leq_pred_pred : forall (m n: nat), m <= n -> m.-1 <= n.-1.
Proof.
  move=> m n leqH. rewrite -2!subn1. by apply/(leq_sub2r 1): leqH.
Qed.
End missingLemmas.

Section toomCook.

Variable R : idomainType.
Implicit Types p q : {poly R}.

Variable number_splits : nat.
Definition m : nat := number_splits.
Definition number_points := (2 * m) .-1.
Variable inter_points : 'cV[{poly R}]_(number_points).

Hypothesis m_geq3 : 3 <= m.

Definition V_e : 'M[{poly R}]_(number_points, m) :=
  \matrix_(i < number_points, j < m) ((inter_points i 0))^+j.

Definition V_eT : 'M[{poly R}]_(m, number_points) :=
  \matrix_(i < m, j < number_points) ((inter_points j 0))^+i.

Definition V_I : 'M[{poly R}]_(number_points) :=
 \matrix_(i < number_points, j < number_points) ((inter_points i 0))^+j.

Hypothesis unitV_I : unitmx V_I.

Lemma V_eTr_eq_V_eT : V_e^T = V_eT.
Proof. by apply/matrixP => i j; rewrite 3!mxE. Qed.

Definition exponent (m: nat) p q : nat :=
  (maxn (divn (size p) m) (divn (size q) m)).+1.

Definition split (n b: nat) p : {poly {poly R}} :=
  \poly_(i < n) rmodp (rdivp p 'X^(i * b)) 'X^b.

Definition evaluate (u: {poly {poly R}}) : 'cV[{poly R}]_(number_points) :=
  V_e *m (poly_rV u)^T.

Definition evaluateT (u: {poly {poly R}}) : 'rV[{poly R}]_(number_points) :=
  (poly_rV u) *m V_eT .

Definition interpolate (u: 'cV[{poly R}]_(number_points)) : {poly {poly R}} :=
  rVpoly (invmx V_I *m u)^T.

Definition recompose (b: nat) (w: {poly {poly R}}) : {poly R} :=
  w.['X^b].

Fixpoint toom_cook_rec (n: nat) p q : {poly R} :=
  match n with
  | 0%N => p * q
  | n'.+1 => if (size p <= 2) || (size q <= 2) then p * q else
        let b := exponent m p q in
        let u := split m b p in
        let v := split m b q in
        let u_a := evaluate u in
        let v_a:= evaluate v in
        let w_a := \col_i toom_cook_rec n' (u_a i 0) (v_a i 0) in
        let w := interpolate w_a
         in recompose b w
  end.

Lemma eval_T_eq_evalT : forall (u: {poly {poly R}}),
  evaluate u = (evaluateT u)^T.
Proof.
  move=> u.
  by rewrite /evaluate trmx_mul -V_eTr_eq_V_eT trmxK.
Qed.

Lemma matrix_evaluationT : forall (p: {poly R}) (b: nat) (i: 'I_number_points),
  evaluateT (split m b p) 0 i = (split m b p).[(inter_points i 0)].
Proof.
  move=> p b t.
  rewrite /evaluateT /mulmx /V_eT /poly_rV /split.
  rewrite horner_poly mxE.
  apply: eq_bigr => i _.
  rewrite !mxE coef_poly.
  case: ifP => [ // | ].
    by move: (ltn_ord i) => ->.
Qed.

Lemma matrix_evaluation : forall p (b: nat) (i: 'I_number_points),
  evaluate (split m b p) i 0 = (split m b p).[(inter_points i 0)].
Proof.
  move=> p b t.
  by rewrite eval_T_eq_evalT mxE matrix_evaluationT.
Qed.

Lemma matrix_evaluation2 : forall p (b: nat),
  evaluate (split m b  p) = \col_j (split m b p).[(inter_points j 0)].
Proof.
  move=> u t.
  apply/colP => i.
  by rewrite [X in _ = X]mxE -matrix_evaluation.
Qed.

Lemma toom_cook_interpol_lemma0 : forall (f: {poly {poly R}}),
  size f <= number_points ->
  unitmx V_I ->
  invmx V_I *m \col_i f.[inter_points i 0] = (poly_rV f)^T.
Proof.
  move=> f fsizeH unitV_I2.
  rewrite -[X in _ = X](mulKmx unitV_I2).

  have->: \col_i f.[inter_points i 0] = V_I *m (poly_rV f)^T.
    apply/matrixP => i j.
    rewrite !mxE (@horner_coef_wide _ number_points).
    apply: eq_bigr => k _.
    by rewrite !mxE mulrC.
    by apply: fsizeH.

  done.
Qed.

Lemma toom_cook_interpol : forall (f: {poly {poly R}}) (k: nat),
  size f <= number_points -> unitmx V_I ->
  (interpolate (\col_i (f.[(inter_points i 0)]))) = f.
Proof.
  move=> f k leq unitV_I2.
  by rewrite -{2}(poly_rV_K leq) /interpolate (toom_cook_interpol_lemma0 leq unitV_I2) trmxK.
Qed.

Lemma rdivpXn_drop : forall p n, rdivp p 'X^n = Poly (drop n p).
Proof.
elim/poly_ind=> [n|p c ih [|n]]; first by rewrite rdiv0p polyseq0.
  rewrite expr0 rdivp1 drop0; apply/poly_inj.
  by rewrite (@PolyK _ 1 (p * 'X + c%:P)) //; case: (p * 'X + c%:P).
rewrite {1}[p](rdivp_eq (monicXn _ n)) mulrDl -mulrA -exprSr -addrA.
rewrite rdivp_addl_mul_small ?rmodp_addl_mul_small ?monicXn //.
  rewrite -cons_poly_def ih polyseq_cons.
  by have [-> /=| //] := nilP; rewrite polyseqC; case: (c == 0).
rewrite size_polyXn size_MXaddC ltnS; case: ifP => // _.
by rewrite (leq_trans (ltn_rmodpN0 _ _)) ?monic_neq0 ?monicXn ?size_polyXn.
Qed.

Lemma drop_addn : forall n m (s : seq R) , drop (m + n) s = drop m (drop n s).
Proof.
by elim=> [m s|m ih n [] //= a l]; rewrite ?addn0 ?drop0 // addnS ih.
Qed.

Lemma last_drop c n (s : seq R) : n < size s -> last c (drop n s) = last c s.
Proof.
elim/last_ind: s => //= s a _ hs.
by rewrite drop_rcons ?last_rcons; rewrite size_rcons ltnS in hs.
Qed.

Lemma recompose_split_lemma0 p m n :
  rdivp p ('X^m * 'X^n) = rdivp (rdivp p 'X^m) 'X^n.
Proof.
rewrite -exprD !rdivpXn_drop drop_addn.
by apply/polyP=> i; rewrite ?(coef_Poly,nth_drop) addnCA.
Qed.

Lemma rdivXn_size p n : size (rdivp p 'X^n) = (size p - n)%N.
Proof.
rewrite rdivpXn_drop -size_drop (@PolyK _ 1 (drop n p)) //.
have [hsp|hsp] := ltnP n (size p); last by rewrite drop_oversize // oner_neq0.
by rewrite last_drop // {hsp}; case: p.
Qed.

Lemma recompose_split_lemma1 : forall (f: {poly R}) (k b: nat),
  (rmodp (rdivp f 'X^(k*b)) 'X^(b)) * 'X^(k*b) +
  (rdivp f 'X^(k.+1*b)) * 'X^(k.+1*b) = (rdivp f 'X^(k*b)) * 'X^(k*b).
Proof.
  move => f k b.
  rewrite {1}mulSnr mulSn 2!exprD mulrA -mulrDl addrC recompose_split_lemma0.
  rewrite -rdivp_eq.
  done.
  by rewrite monicXn.
Qed.

Lemma recompose_split_lemma2 : forall (f: {poly R}) (k b: nat),
  \big[+%R/0]_(i < k.+1) ((rmodp (rdivp f 'X^(i*b)) 'X^b)*'X^(i*b)) +
  (rdivp f 'X^(k.+1*b))*'X^(k.+1*b) =
  \big[+%R/0]_(i < k) ((rmodp (rdivp f 'X^(i*b)) 'X^b)*'X^(i*b)) +
  (rdivp f 'X^(k*b))*'X^(k*b).
Proof.
  move=> f k b.
  symmetry.
  by rewrite big_ord_recr //= -recompose_split_lemma1 addrA.
Qed.

Lemma recompose_split_lemma3 : forall (f : {poly R}) (k b : nat),
  \big[+%R/0]_(i < k.+1) ((rmodp (rdivp f 'X^(i*b)) 'X^b)*'X^(i*b)) +
  (rdivp f 'X^(k.+1*b))*'X^(k.+1*b) = f.
Proof.
  move=> f k b.
  elim: k => [ | n IH ].
    rewrite big_ord_recr //=.
    rewrite big_ord0 add0r mul0n rdivp1 mulr1 mul1n addrC.
    rewrite -rdivp_eq.
    done.
    by rewrite monicXn.
    by rewrite recompose_split_lemma2 IH.
Qed.

Lemma recompose_split : forall (f: {poly R}) (b: nat),
  size f <= m * b ->
  (split m b f).['X^b] = f.
Proof.
  move=> f b.

  case: m.
    rewrite mul0n size_poly_leq0.
    move/eqP ->.
    by rewrite horner_poly big_ord0.
  case=> [ H | n H ].
    rewrite mul1n in H.
    rewrite horner_poly big_ord_recr //=.
    rewrite big_ord0 mul0n !expr0 mulr1 rdivp1 add0r.
    rewrite rmodp_small.
    done.
    by rewrite size_polyXn.

    rewrite horner_poly big_ord_recr //=.
    rewrite rmodp_small.
    rewrite -exprM.
    rewrite mulnC.
    rewrite mulnC.
    have ->: \big[+%R/0]_(i < succn n) (rmodp (R:=R) (rdivp (R:=R)
                    f 'X^(i * b)) 'X^b * 'X^b ^+ i) =
                    \big[+%R/0]_(i < succn n) (rmodp (R:=R) (rdivp (R:=R)
                    f 'X^(i * b)) 'X^b * 'X^(i*b)).
      apply: eq_bigr => j t.
      by rewrite -exprM mulnC.

    by rewrite recompose_split_lemma3.

    by rewrite size_polyXn ltnS rdivXn_size leq_subLR addnC -mulSn.
Qed.

Lemma exp_m_degree_lemma : forall p,
  m > 0 ->
  size p <= m * succn (size p %/ m).
Proof.
  by move=> p H; rewrite mulnC; apply: (ltnW (ltn_ceil (size _) _)).
Qed.

Lemma exp_m_degree : forall p q,
  size p <= m * exponent m p q.
Proof.
  move=> p q.
  rewrite /exponent.
  suff: size p <= m * (size p %/ m).+1.
  move=> sp.

  have: succn (size p %/ m) <= succn (maxn (size p %/ m) (size q %/ m)).
    by apply/leq_maxl.
  move=> H.

  have: m * succn (size p %/ m) <= m * succn (maxn (size p %/ m) (size q %/ m)).
    apply/leq_mul.
    done.
    by apply/H.
  move=> G.

  apply: (leq_trans sp G).
  apply: exp_m_degree_lemma.
  move: (leqnSn 1) => J.
  by apply: (ltn_trans J m_geq3).
Qed.

Lemma exponentC : forall p q, exponent m p q = exponent m q p.
Proof.
  by move=> p q; rewrite /exponent maxnC.
Qed.

Lemma split_size_leq_m: forall (p: {poly R}) (b: nat),
 size (split m b p) <= m.
Proof.
 by move=> p b; rewrite size_poly.
Qed.

Lemma size_split_mul : forall p q,
  size (split m (exponent m p q) p * split m (exponent m p q) q) <= number_points.
Proof.
  move=> p q.
  set b := (exponent m p q).
  set u := split m b p.
  set v := split m b q.
  move: (split_size_leq_m p b) (split_size_leq_m q b).
  move: (size_mul_leq u v) => sizeH sizeu sizev.
  rewrite /number_points mul2n -addnn.
  rewrite (leq_trans sizeH) //.
  by apply: leq_pred_pred (leq_add sizeu sizev).
Qed.

Lemma toom_cook_rec_correct : forall (n : nat) p q,
  unitmx V_I -> toom_cook_rec n p q = p * q.
Proof.
  elim=> [ // | n IHn p q V_invbar ] /=.
    case: ifP => [ // | H ].
      move/IHn: V_invbar => IH2.

      set b := (exponent m p q).
      set u := split m b p.
      set v := split m b q.

      have ->:
        \col_i toom_cook_rec n ((evaluate u) i 0) ((evaluate v) i 0) =
        \col_i ((evaluate u) i 0 * (evaluate v) i 0).
          apply/colP => j.
          by rewrite mxE [X in _ = X]mxE IH2.

      rewrite /recompose.
      rewrite !matrix_evaluation2.

      have ->:
        \col_i ((\col_j u.[inter_points j 0]) i 0 * (\col_j v.[inter_points j 0]) i 0) =
        \col_i (u * v).[(inter_points i 0)].
          apply/colP => k.
          by rewrite 4!mxE -hornerM.

      rewrite toom_cook_interpol ?hornerM ?recompose_split.
      done.

    rewrite /b exponentC.
    by apply/exp_m_degree.

    by apply/exp_m_degree.

    done.
    by apply: size_split_mul.
    by apply: unitV_I.
Qed.

Definition toom_cook p q : {poly R} :=
  toom_cook_rec (maxn (size p) (size q)) p q.

Lemma toom_cook_correct : forall p q,
  toom_cook p q = p * q.
Proof.
  move=> p q.
  by rewrite /toom_cook toom_cook_rec_correct.
Qed.

End toomCook.
