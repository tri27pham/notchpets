import Foundation

enum AnimationState: String, CaseIterable {
    case idle
    case happy
    case eating
    case playing
    case sleeping
    case sad
    case dancing
    case run
    case jump
    case catchBall = "catch_ball"
}

struct AnimationDef {
    let row: Int        // 0-indexed row in the spritesheet
    let frameCount: Int
    let fps: Int
    let loops: Bool
}

let penguinManifest: [AnimationState: AnimationDef] = [
    .idle:      AnimationDef(row: 0, frameCount: 2, fps: 4,  loops: true),
    .happy:     AnimationDef(row: 1, frameCount: 6, fps: 10, loops: false),
    .eating:    AnimationDef(row: 2, frameCount: 6, fps: 6,  loops: false),
    .playing:   AnimationDef(row: 3, frameCount: 6, fps: 8, loops: false),
    .sleeping:  AnimationDef(row: 4, frameCount: 4, fps: 4,  loops: true),
    .sad:       AnimationDef(row: 5, frameCount: 4, fps: 4,  loops: true),
    .dancing:   AnimationDef(row: 6, frameCount: 6, fps: 10, loops: false),
    .run:       AnimationDef(row: 7, frameCount: 6, fps: 12, loops: true),
    .jump:      AnimationDef(row: 8, frameCount: 4, fps: 10, loops: false),
    .catchBall: AnimationDef(row: 9, frameCount: 4, fps: 10, loops: false),
]
