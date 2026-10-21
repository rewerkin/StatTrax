import Foundation
import SwiftData

enum MatchResult: String, Codable, CaseIterable {
    case scheduled
    case win
    case draw
    case loss
}

@Model
final class Team {
    var name: String
    var shortName: String
    var season: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Player.team)
    var players: [Player] = []

    @Relationship(deleteRule: .cascade, inverse: \Match.team)
    var matches: [Match] = []

    init(
        name: String,
        shortName: String,
        season: String,
        createdAt: Date = .now
    ) {
        self.name = name
        self.shortName = shortName
        self.season = season
        self.createdAt = createdAt
    }
}

@Model
final class Player {
    var name: String
    var number: Int
    var position: String
    var dateOfBirth: Date?
    var team: Team?

    @Relationship(deleteRule: .cascade, inverse: \PlayerMatchStat.player)
    var matchStats: [PlayerMatchStat] = []

    init(
        name: String,
        number: Int,
        position: String,
        dateOfBirth: Date? = nil,
        team: Team? = nil
    ) {
        self.name = name
        self.number = number
        self.position = position
        self.dateOfBirth = dateOfBirth
        self.team = team
    }
}

@Model
final class Match {
    var opponent: String
    var date: Date
    var venue: String
    var goalsFor: Int
    var goalsAgainst: Int
    var resultRawValue: String
    var team: Team?

    @Relationship(deleteRule: .cascade, inverse: \PlayerMatchStat.match)
    var playerStats: [PlayerMatchStat] = []

    var result: MatchResult {
        get { MatchResult(rawValue: resultRawValue) ?? .scheduled }
        set { resultRawValue = newValue.rawValue }
    }

    init(
        opponent: String,
        date: Date,
        venue: String,
        goalsFor: Int = 0,
        goalsAgainst: Int = 0,
        result: MatchResult = .scheduled,
        team: Team? = nil
    ) {
        self.opponent = opponent
        self.date = date
        self.venue = venue
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.resultRawValue = result.rawValue
        self.team = team
    }
}

@Model
final class PlayerMatchStat {
    var minutesPlayed: Int
    var goals: Int
    var assists: Int
    var shots: Int
    var passesCompleted: Int
    var yellowCards: Int
    var redCards: Int
    var player: Player?
    var match: Match?

    init(
        minutesPlayed: Int = 0,
        goals: Int = 0,
        assists: Int = 0,
        shots: Int = 0,
        passesCompleted: Int = 0,
        yellowCards: Int = 0,
        redCards: Int = 0,
        player: Player? = nil,
        match: Match? = nil
    ) {
        self.minutesPlayed = minutesPlayed
        self.goals = goals
        self.assists = assists
        self.shots = shots
        self.passesCompleted = passesCompleted
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.player = player
        self.match = match
    }
}
