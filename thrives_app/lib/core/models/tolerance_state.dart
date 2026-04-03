// CLINICAL SAFETY — ToleranceState gating
// What this does: Defines the three Window of Tolerance states and which tools
//   are safe and appropriate in each state.
// Why it exists: Wrong tool in wrong state deepens dysregulation. A person in
//   freeze does not need more calming. A person in acute panic does not need
//   processing tools that require cognitive capacity to use safely.
// What happens if removed or modified: Users in hyperaroused or hypoaroused
//   states may access tools that are contraindicated for their current state,
//   increasing risk of deepened dysregulation or retraumatisation.
// Informed by: Marit Leito, clinical advisor / Ogden et al., sensorimotor
//   psychotherapy / Siegel, Window of Tolerance model.

enum ToleranceState { hyperaroused, regulated, hypoaroused }

extension ToleranceStateGating on ToleranceState {
  /// Box breathing — balanced and regulating. Safe in all states.
  bool get canBoxBreathe => true;

  // CLINICAL SAFETY — 4-7-8 lock
  // What this does: Prevents access to 4-7-8 when dysregulated.
  // Why it exists: Long breath holds increase CO2 tolerance demands. In
  //   hyperaroused state this can trigger panic. In hypoaroused state it
  //   deepens dissociation and freeze.
  // What happens if removed: Contraindicated technique becomes available in
  //   states where it causes harm.
  // Informed by: Marit Leito, clinical advisor.
  bool get can4_7_8 => this == ToleranceState.regulated;

  // CLINICAL SAFETY — Wim Hof lock
  // What this does: Locks Wim Hof unless user is regulated.
  // Why it exists: Deliberate hyperventilation in a dysregulated nervous
  //   system is dangerous. Can cause fainting, panic escalation, or cardiac
  //   stress. Even when regulated, requires full contraindication screen.
  // What happens if removed: Serious physical harm is a real possibility.
  // Informed by: Marit Leito, clinical advisor / published Wim Hof safety
  //   literature.
  bool get canWimHof => this == ToleranceState.regulated;

  // CLINICAL SAFETY — Safe place lock
  // What this does: Locks safe place visualisation when dysregulated.
  // Why it exists: Guided visualisation requires the capacity to access and
  //   hold internal imagery. In acute hyperarousal or freeze, this capacity
  //   is not available. Attempting it can increase frustration and distress.
  // What happens if removed: Users attempt a technique they cannot access,
  //   increasing distress.
  // Informed by: Marit Leito, clinical advisor.
  bool get canSafePlace => this == ToleranceState.regulated;

  // CLINICAL SAFETY — Bilateral stimulation lock
  // What this does: Locks bilateral stimulation unless user is regulated.
  // Why it exists: Processing trauma requires a regulated nervous system as
  //   the container. Without that foundation, bilateral stimulation can
  //   activate trauma material without the capacity to process it, increasing
  //   distress or triggering retraumatisation.
  // What happens if removed: Risk of retraumatisation for users in acute
  //   dysregulated states.
  // Informed by: Marit Leito, clinical advisor / Francine Shapiro,
  //   EMDR preparation phase requirements.
  bool get canBilateral => this == ToleranceState.regulated;

  /// Cold water / diving reflex — immediate vagal activation. Safe in all states.
  bool get canColdWater => true;

  /// 5-4-3-2-1 grounding — sensory anchoring. Safe and beneficial in all states.
  bool get canGround => true;

  /// Vagal prompts — humming, gargling, extended exhale. Safe in all states.
  bool get canVagal => true;

  /// User-facing label. No clinical terminology.
  String get displayName {
    switch (this) {
      case ToleranceState.hyperaroused:
        return 'overwhelmed';
      case ToleranceState.regulated:
        return 'present';
      case ToleranceState.hypoaroused:
        return 'flat or numb';
    }
  }

  /// Short explanation shown on locked tool cards.
  String get lockedReason {
    switch (this) {
      case ToleranceState.hyperaroused:
        return 'not available when overwhelmed';
      case ToleranceState.regulated:
        return '';
      case ToleranceState.hypoaroused:
        return 'not available when flat';
    }
  }
}
