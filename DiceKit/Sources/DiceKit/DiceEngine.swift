public enum DiceEngine {
    /// Rolls `spec`, which must already pass `validate()`.
    public static func roll<G: RandomNumberGenerator>(_ spec: RollSpec, using rng: inout G) -> RollResult {
        precondition((try? spec.validate()) != nil, "DiceEngine.roll requires a valid RollSpec")
        let dice = (0..<spec.diceToRoll).map { _ in Int.random(in: 1...spec.sides, using: &rng) }
        let bonusRolls = spec.extras.map { group in
            (0..<group.count).map { _ in Int.random(in: 1...group.sides, using: &rng) }
        }
        return evaluate(spec, dice: dice, bonusRolls: bonusRolls)
    }

    /// Pure scoring of already-rolled dice; also used to recompute results when decoding.
    /// `bonusRolls` holds each bonus group's dice, aligned with `spec.extras`.
    public static func evaluate(_ spec: RollSpec, dice: [Int], bonusRolls: [[Int]] = []) -> RollResult {
        let kept: [Int]
        switch spec.mode {
        case .normal:
            kept = Array(dice.indices)
        case .advantage:
            kept = dice.indices.first(where: { dice[$0] == dice.max() }).map { [$0] } ?? []
        case .disadvantage:
            kept = dice.indices.first(where: { dice[$0] == dice.min() }).map { [$0] } ?? []
        }

        let bonus = zip(spec.extras, bonusRolls).reduce(0) { sum, pair in
            let groupSum = pair.1.reduce(0, +)
            return sum + (pair.0.sign == .plus ? groupSum : -groupSum)
        }
        let total = kept.reduce(0) { $0 + dice[$1] } + bonus + spec.modifier

        var critical = Critical.none
        if spec.isSingleD20, spec.criticalsEnabled, let index = kept.first {
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

        return RollResult(dice: dice, keptIndices: kept, bonusRolls: bonusRolls, total: total, critical: critical,
                          dcOutcome: dcOutcome)
    }
}
