public enum DiceEngine {
    /// Rolls `spec`, which must already pass `validate()`.
    public static func roll<G: RandomNumberGenerator>(_ spec: RollSpec, using rng: inout G) -> RollResult {
        precondition((try? spec.validate()) != nil, "DiceEngine.roll requires a valid RollSpec")
        let dice = (0..<spec.diceToRoll).map { _ in Int.random(in: 1...spec.sides, using: &rng) }
        return evaluate(spec, dice: dice)
    }

    /// Pure scoring of already-rolled dice; also used to recompute results when decoding.
    public static func evaluate(_ spec: RollSpec, dice: [Int]) -> RollResult {
        let kept: [Int]
        switch spec.mode {
        case .normal:
            kept = Array(dice.indices)
        case .advantage:
            kept = dice.indices.first(where: { dice[$0] == dice.max() }).map { [$0] } ?? []
        case .disadvantage:
            kept = dice.indices.first(where: { dice[$0] == dice.min() }).map { [$0] } ?? []
        }

        let total = kept.reduce(0) { $0 + dice[$1] } + spec.modifier

        var critical = Critical.none
        if spec.isSingleD20, let index = kept.first {
            if dice[index] == 20 { critical = .success }
            if dice[index] == 1 { critical = .failure }
        }

        let dcOutcome: DCOutcome? = spec.dc.map { dc in
            switch critical {
            case .success: return .success
            case .failure: return .failure
            case .none: return total >= dc ? .success : .failure
            }
        }

        return RollResult(dice: dice, keptIndices: kept, total: total, critical: critical, dcOutcome: dcOutcome)
    }
}
