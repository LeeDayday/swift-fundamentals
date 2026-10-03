struct Player {
    var score: Int
}

func addBonus(to player: inout Player) {
    player.score += 10
}

func reset(_ player: Player) {
    var copy = player
    copy.score = 0

    print("inside reset: ", copy.score)
}

var player = Player(score: 50)

addBonus(to: &player)
print("after bonus: ", player.score)

reset(player)
print("after reset: ", player.score)

//  MARK: - inout requires a mutable value

// let fixedPlayer = Player(score: 50)
// addBonus(to: &fixedPlayer) // Compile Error

// MARK: - Exclusive Access

func compareAndUpdate(
    _ first: inout Player,
    _ second: inout Player
) {
    first.score += 10
    second.score += 20
}

// var anotherPlayer = Player(score: 50)
// compareAndUpdate(&anotherPlayer, &anotherPlayer
)