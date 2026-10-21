import SwiftData
import SwiftUI

private enum DashboardSheet: String, Identifiable {
    case addPlayer
    case addMatch

    var id: String { rawValue }
}

struct ContentView: View {
    @Query private var teams: [Team]
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @Query private var players: [Player]
    @AppStorage("appAppearance") private var appAppearance = "system"
    @AppStorage("selectedTeamName") private var selectedTeamName = ""
    @State private var activeSheet: DashboardSheet?
    @State private var showingPlayers = false
    @State private var showingTeamSetup = false

    private var selectedTeam: Team? {
        teams.first { $0.name == selectedTeamName } ?? teams.first
    }

    private var selectedTeamPlayers: [Player] {
        guard let selectedTeam else { return [] }
        return players.filter { $0.team?.name == selectedTeam.name || (teams.count == 1 && $0.team == nil) }
    }

    private var selectedTeamMatches: [Match] {
        guard let selectedTeam else { return [] }
        return matches.filter { $0.team?.name == selectedTeam.name || (teams.count == 1 && $0.team == nil) }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appAppearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    var body: some View {
        NavigationStack {
            if teams.isEmpty {
                TeamSetupView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        DashboardHeader()
                        Button {
                            showingPlayers = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.3ƒ.fill")
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                                    .frame(width: 42, height: 42)
                                    .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Players").font(.headline).foregroundStyle(.primary)
                                    Text("View and manage your roster").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(selectedTeamPlayers.count)")
                                    .font(.system(.title3, design: .monospaced, weight: .bold))
                                    .foregroundStyle(.blue)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        OverviewSection(
                            playerCount: selectedTeamPlayers.count,
                            matchCount: selectedTeamMatches.count,
                            teamName: selectedTeam?.name ?? "Your team"
                        )
                        TeamStatsSection(matches: selectedTeamMatches.filter { $0.result != .scheduled })
                        Button {
                            activeSheet = .addMatch
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                                    .frame(width: 42, height: 42)
                                    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Add Match").font(.headline).foregroundStyle(.primary)
                                    Text("Record a fixture or result").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        RecentMatchesSection(matches: Array(selectedTeamMatches.prefix(3)))
                        PlayerLeadersSection(players: Array(selectedTeamPlayers.prefix(4)))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .background(Color.gray.opacity(0.12))
                .navigationTitle("Matchday")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Menu {
                                Picker("Appearance", selection: $appAppearance) {
                                    Text("System").tag("system")
                                    Text("Light").tag("light")
                                    Text("Dark").tag("dark")
                                }
                            } label: {
                                Label("Appearance", systemImage: "paintbrush")
                            }

                            Menu {
                                ForEach(teams) { team in
                                    Button {
                                        selectedTeamName = team.name
                                    } label: {
                                        if selectedTeam?.name == team.name {
                                            Label(team.name, systemImage: "checkmark")
                                        } else {
                                            Text(team.name)
                                        }
                                    }
                                }
                            } label: {
                                Label("Team: \(selectedTeam?.name ?? "Select")", systemImage: "person.3")
                            }

                            Divider()

                            Button {
                                showingPlayers = true
                            } label: {
                                Label("Manage Players", systemImage: "person.3.fill")
                            }
                            Button {
                                activeSheet = .addPlayer
                            } label: {
                                Label("Add Player", systemImage: "person.badge.plus")
                            }
                            Button {
                                activeSheet = .addMatch
                            } label: {
                                Label("Add Match", systemImage: "calendar.badge.plus")
                            }
                            Button {
                                showingTeamSetup = true
                            } label: {
                                Label("Add Team", systemImage: "plus.rectangle.on.folder")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.headline)
                                .accessibilityLabel("Dashboard menu")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            activeSheet = .addPlayer
                        } label: {
                            Label("Add Player", systemImage: "person.badge.plus")
                        }
                    }
                }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .addPlayer:
                        AddPlayerView(team: selectedTeam)
                    case .addMatch:
                        AddMatchView(team: selectedTeam)
                    }
                }
                .navigationDestination(isPresented: $showingPlayers) {
                    PlayersView(team: selectedTeam)
                }
                .navigationDestination(isPresented: $showingTeamSetup) {
                    TeamSetupView()
                }
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .onChange(of: teams.map(\.name), initial: true) { _, teamNames in
            if selectedTeamName.isEmpty || !teamNames.contains(selectedTeamName) {
                selectedTeamName = teamNames.first ?? ""
            }
        }
    }
}

private struct TeamStatsSection: View {
    let matches: [Match]

    private var wins: Int { matches.filter { $0.result == .win }.count }
    private var draws: Int { matches.filter { $0.result == .draw }.count }
    private var losses: Int { matches.filter { $0.result == .loss }.count }
    private var goalsFor: Int { matches.reduce(0) { $0 + $1.goalsFor } }
    private var goalsAgainst: Int { matches.reduce(0) { $0 + $1.goalsAgainst } }

    var body: some View {
        DashboardSection(title: "Team stats", subtitle: "Season to date") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    MetricCard(title: "Wins", value: "\(wins)", icon: "trophy.fill", tint: .green)
                    MetricCard(title: "Draws", value: "\(draws)", icon: "equal", tint: .orange)
                    MetricCard(title: "Losses", value: "\(losses)", icon: "xmark", tint: .red)
                }
                HStack(spacing: 12) {
                    MetricCard(title: "Goals for", value: "\(goalsFor)", icon: "StatTrackerIconArtwork", tint: .blue)
                    MetricCard(title: "Goals against", value: "\(goalsAgainst)", icon: "shield.fill", tint: .purple)
                }
            }
        }
    }
}

private struct SetupPlayerDraft: Identifiable {
    let id = UUID()
    let name: String
    let number: Int
    let position: String
}

private struct TeamSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingTeams: [Team]
    @AppStorage("selectedTeamName") private var selectedTeamName = ""
    @State private var step = 0
    @State private var teamName = ""
    @State private var roster: [SetupPlayerDraft] = []
    @State private var playerName = ""
    @State private var playerNumber = ""
    @State private var playerPosition = ""
    @State private var opponent = ""
    @State private var goalsFor = "0"
    @State private var goalsAgainst = "0"
    @State private var matchDate = Date.now
    @State private var venue = "Home"
    @State private var saveError: String?

    private var cleanTeamName: String {
        teamName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var teamNameIsAvailable: Bool {
        !existingTeams.contains { $0.name.localizedCaseInsensitiveCompare(cleanTeamName) == .orderedSame }
    }

    private var canAddPlayer: Bool {
        !playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(playerNumber) != nil &&
        !playerPosition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DashboardHeader()
                VStack(alignment: .leading, spacing: 8) {
                    Text("GETTING STARTED")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(stepTitle)
                        .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                    Text(stepDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index <= step ? Color.green : Color.gray.opacity(0.2))
                            .frame(height: 6)
                    }
                }

                setupContent

                Button(action: advance) {
                    HStack {
                        Spacer()
                        Text(step == 2 ? "Create Team" : "Continue")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                        Spacer()
                    }
                    .padding(.vertical, 15)
                    .foregroundStyle(.white)
                    .background(Color.green, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(step == 0 && (cleanTeamName.isEmpty || !teamNameIsAvailable))
                .opacity(step == 0 && (cleanTeamName.isEmpty || !teamNameIsAvailable) ? 0.5 : 1)

                if step > 0 {
                    Button("Back") { step -= 1 }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
                if step == 2 {
                    Button("Skip first match for now") { saveSetup(includeMatch: false) }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.gray.opacity(0.12))
        .navigationTitle("Team Setup")
        .alert("Couldn’t save team", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    @ViewBuilder
    private var setupContent: some View {
        switch step {
        case 0:
            VStack(alignment: .leading, spacing: 12) {
                Text("Team name").font(.headline)
                TextField("For example, Northside FC", text: $teamName)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                if !cleanTeamName.isEmpty && !teamNameIsAvailable {
                    Text("A team with this name already exists.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Text("You can change team details later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case 1:
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 10) {
                    TextField("Player name", text: $playerName)
                    TextField("Jersey number", text: $playerNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: playerNumber) { _, value in
                            let digits = value.filter(\.isNumber)
                            if digits != value { playerNumber = digits }
                        }
                    TextField("Position", text: $playerPosition)
                }
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

				Button(action: addDraftPlayer) {
                    Label("Add to roster", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canAddPlayer)
                .opacity(canAddPlayer ? 1 : 0.5)

                if !roster.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(roster) { player in
                            HStack(spacing: 12) {
                                Text("\(player.number)")
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                                    .frame(width: 40, height: 40)
                                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(player.name).font(.headline)
                                    Text(player.position).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) { roster.removeAll { $0.id == player.id } } label: {
                                    Image(systemName: "minus.circle")
                                }
                            }
                            .padding(12)
                            if player.id != roster.last?.id { Divider().padding(.leading, 64) }
                        }
                    }
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    EmptyDashboardCard(icon: "person.3", title: "Roster is ready", message: "Add players now, or continue and add them later.")
                }
            }
        default:
            VStack(alignment: .leading, spacing: 16) {
                Text("Add a completed match to start your team stats. Wins, draws, losses, and goals will be calculated from match results.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                VStack(spacing: 12) {
                    TextField("Opponent", text: $opponent)
                        .textInputAutocapitalization(.words)
                    DatePicker("Match date", selection: $matchDate, displayedComponents: .date)
                    Picker("Venue", selection: $venue) {
                        Text("Home").tag("Home")
                        Text("Away").tag("Away")
                    }
                    HStack {
                        TextField("Your goals", text: $goalsFor).keyboardType(.numberPad)
                        Text("–")
                        TextField("Opponent goals", text: $goalsAgainst).keyboardType(.numberPad)
                    }
                    .multilineTextAlignment(.center)
                    .onChange(of: goalsFor) { _, value in
                        let digits = value.filter(\.isNumber)
                        if digits != value { goalsFor = digits }
                    }
                    .onChange(of: goalsAgainst) { _, value in
                        let digits = value.filter(\.isNumber)
                        if digits != value { goalsAgainst = digits }
                    }
                }
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var stepTitle: String {
        ["Who is Your Team?", "Build your roster", "Add your team stats"][step]
    }

    private var stepDescription: String {
        ["Set up your team workspace.", "Add players now, or skip straight to the next step.", "Record a completed match to start tracking team performance."][step]
    }

    private func addDraftPlayer() {
        guard canAddPlayer, let number = Int(playerNumber) else { return }
        roster.append(SetupPlayerDraft(
            name: playerName.trimmingCharacters(in: .whitespacesAndNewlines),
            number: number,
            position: playerPosition.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        playerName = ""
        playerNumber = ""
        playerPosition = ""
    }

    private func advance() {
        if step < 2 {
            step += 1
        } else {
            saveSetup(includeMatch: !opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func saveSetup(includeMatch: Bool) {
        let isAdditionalTeam = !existingTeams.isEmpty
        let shortName = String(cleanTeamName.split(separator: " ").compactMap(\.first).prefix(4))
        let team = Team(name: cleanTeamName, shortName: shortName, season: String(Calendar.current.component(.year, from: .now)))
        modelContext.insert(team)
        selectedTeamName = team.name

        for entry in roster {
            modelContext.insert(Player(name: entry.name, number: entry.number, position: entry.position, team: team))
        }

        if includeMatch,
           !opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let forGoals = Int(goalsFor), let againstGoals = Int(goalsAgainst) {
            let result: MatchResult = forGoals > againstGoals ? .win : (forGoals == againstGoals ? .draw : .loss)
            modelContext.insert(Match(
                opponent: opponent.trimmingCharacters(in: .whitespacesAndNewlines),
                date: matchDate,
                venue: venue,
                goalsFor: forGoals,
                goalsAgainst: againstGoals,
                result: result,
                team: team
            ))
        }
        do {
            try modelContext.save()
            if isAdditionalTeam {
                dismiss()
            }
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }
}

private struct PlayersView: View {
    @Query private var players: [Player]
    let team: Team?
    @State private var showingAddPlayer = false
    @State private var searchText = ""

    private var teamPlayers: [Player] {
        guard let team else { return players }
        return players.filter { $0.team?.name == team.name }
    }

    private var filteredPlayers: [Player] {
        let ordered = teamPlayers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard !searchText.isEmpty else { return ordered }
        return ordered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.position.localizedCaseInsensitiveContains(searchText) ||
            String($0.number).contains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TEAM ROSTER")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Players")
                        .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                    Text(team?.name ?? "Your squad at a glance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    MetricCard(title: "Players", value: "\(teamPlayers.count)", icon: "person.3.fill", tint: .blue)
                    MetricCard(title: "Positions", value: "\(Set(teamPlayers.map(\.position)).count)", icon: "sportscourt.fill", tint: .green)
                }

                DashboardSection(title: "Full roster", subtitle: "\(filteredPlayers.count) players") {
                    if filteredPlayers.isEmpty {
                        EmptyDashboardCard(
                            icon: teamPlayers.isEmpty ? "person.crop.circle.badge.plus" : "magnifyingglass",
                            title: teamPlayers.isEmpty ? "No players yet" : "No players found",
                            message: teamPlayers.isEmpty ? "Add your first player to start building the roster." : "Try a different name, number, or position."
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(filteredPlayers) { player in
                                RosterPlayerRow(player: player)
                                if player.id != filteredPlayers.last?.id {
                                    Divider().padding(.leading, 64)

                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.gray.opacity(0.12))
        .navigationTitle("Players")
        .searchable(text: $searchText, prompt: "Search players")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddPlayer = true } label: {
                    Label("Add Player", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlayer) {
            AddPlayerView(team: team)
        }
    }
}

private struct RosterPlayerRow: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            Text("\(player.number)")
                .font(.system(.headline, design: .monospaced, weight: .bold))
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name).font(.headline)
                Text(player.position).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(player.matchStats.reduce(0) { $0 + $1.goals }) G")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.green)
        }
        .padding(.vertical, 12)
    }
}

private enum MatchEntryStatus: String, CaseIterable, Identifiable {
    case scheduled
    case completed

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

private struct AddMatchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let team: Team?
    @State private var opponent = ""
    @State private var matchDate = Date.now
    @State private var venue = "Home"
    @State private var status: MatchEntryStatus = .completed
    @State private var goalsFor = "0"
    @State private var goalsAgainst = "0"
    @State private var saveError: String?

    private var canSave: Bool {
        !opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (status == .scheduled || (Int(goalsFor) != nil && Int(goalsAgainst) != nil))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Match details") {
                    TextField("Opponent", text: $opponent)
                        .textInputAutocapitalization(.words)
                    DatePicker("Date", selection: $matchDate, displayedComponents: .date)
                    Picker("Venue", selection: $venue) {
                        Text("Home").tag("Home")
                        Text("Away").tag("Away")
                    }
                    Picker("Status", selection: $status) {
                        ForEach(MatchEntryStatus.allCases) { entryStatus in
                            Text(entryStatus.title).tag(entryStatus)
                        }
                    }
                }

                if status == .completed {
                    Section("Final score") {
                        HStack {
                            Text("Your team")
                            Spacer()
                            TextField("0", text: $goalsFor)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 56)
                        }
                        .onChange(of: goalsFor) { _, value in
                            let digits = value.filter(\.isNumber)
                            if digits != value { goalsFor = digits }
                        }

                        HStack {
                            Text(opponent.isEmpty ? "Opponent" : opponent)
                            Spacer()
                            TextField("0", text: $goalsAgainst)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 56)
                        }
                        .onChange(of: goalsAgainst) { _, value in
                            let digits = value.filter(\.isNumber)
                            if digits != value { goalsAgainst = digits }
                        }
                    }
                }

                if let team {
                    Section("Team") {
                        LabeledContent("Adding match to", value: team.name)
                    }
                }
            }
            .navigationTitle("Add Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMatch() }
                        .disabled(!canSave)
                }
            }
            .alert("Couldn’t save match", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private func saveMatch() {
        guard canSave else { return }
        let finalGoalsFor = status == .completed ? (Int(goalsFor) ?? 0) : 0
        let finalGoalsAgainst = status == .completed ? (Int(goalsAgainst) ?? 0) : 0
        let result: MatchResult
        if status == .scheduled {
            result = .scheduled
        } else if finalGoalsFor > finalGoalsAgainst {
            result = .win
        } else if finalGoalsFor == finalGoalsAgainst {
            result = .draw
        } else {
            result = .loss
        }

        let match = Match(
            opponent: opponent.trimmingCharacters(in: .whitespacesAndNewlines),
            date: matchDate,
            venue: venue,
            goalsFor: finalGoalsFor,
            goalsAgainst: finalGoalsAgainst,
            result: result,
            team: team
        )
        modelContext.insert(match)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.delete(match)
            saveError = error.localizedDescription
        }
    }
}

private struct AddPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let team: Team?
    @State private var name = ""
    @State private var number = ""
    @State private var position = ""
    @State private var includeBirthDate = false
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -18, to: .now) ?? .now
    @State private var saveError: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Int(number) != nil &&
        !position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player details") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    TextField("Jersey number", text: $number)
                        .onChange(of: number) { _, newValue in
							let digitsOnly = newValue.filter(\.isNumber)
                            if digitsOnly != newValue {
                                number = digitsOnly
                            }
                        }
                    TextField("Position", text: $position)
                }

                Section("Birth date") {
                    Toggle("Add birth date", isOn: $includeBirthDate)
                    if includeBirthDate {
                        DatePicker("Date of birth", selection: $dateOfBirth, displayedComponents: .date)
                    }
                }

                if let team {
                    Section("Team") {
                        LabeledContent("Assigned to", value: team.name)
                    }
                }
            }
            .navigationTitle("New Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePlayer() }
                        .disabled(!canSave)
                }
            }
            .alert("Couldn’t save player", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private func savePlayer() {
        guard let jerseyNumber = Int(number), canSave else { return }
        let player = Player(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            number: jerseyNumber,
            position: position.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: includeBirthDate ? dateOfBirth : nil,
            team: team
        )
        modelContext.insert(player)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }
}

private struct DashboardHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Matchday")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text("Soccer dashboard")
                    .font(.system(.largeTitle, design: .monospaced, weight: .bold))

                Text("A clear home for your team’s season.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image("StatTrackerIconArtwork")
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .padding(7)
                .background(
                    LinearGradient(
                        colors: [
							Color(.sRGB, red: 0.756, green: 0.999, blue: 0.223, opacity: 1),
                            Color(.sRGB, red: 0.204, green: 0.780, blue: 0.349, opacity: 1),
		
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: .green.opacity(0.25), radius: 12, y: 6)
                .accessibilityHidden(true)
        }
    }
}

private struct OverviewSection: View {
    let playerCount: Int
    let matchCount: Int
    let teamName: String

    var body: some View {
        DashboardSection(title: "Overview", subtitle: teamName) {
            HStack(spacing: 12) {
                MetricCard(title: "Players", value: "\(playerCount)", icon: "person.3.fill", tint: .blue)
                MetricCard(title: "Matches", value: "\(matchCount)", icon: "calendar", tint: .orange)
                MetricCard(title: "Season", value: "2026", icon: "chart.line.uptrend.xyaxis", tint: .green)
            }
        }
    }
}

private struct RecentMatchesSection: View {
    let matches: [Match]

    var body: some View {
        DashboardSection(title: "Recent matches", subtitle: "Your latest results") {
            if matches.isEmpty {
                EmptyDashboardCard(
                    icon: "sportscourt",
                    title: "No matches yet",
                    message: "Add your first fixture to start tracking results."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(matches) { match in
                        MatchRow(match: match)
                        if match.id != matches.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }
}

private struct PlayerLeadersSection: View {
	let players: [Player]

    var body: some View {
        DashboardSection(title: "Player leaders", subtitle: "Season totals") {
            if players.isEmpty {
                EmptyDashboardCard(
                    icon: "person.crop.circle.badge.plus",
                    title: "No player data yet",
                    message: "Add players and match stats to see leaders here."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(players) { player in
                        HStack(spacing: 12) {
                            Text("#\(player.number)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(player.name)
                                    .font(.headline)
                                Text(player.position)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(player.matchStats.reduce(0) { $0 + $1.goals }) G")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 12)

                        if player.id != players.last?.id {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }
}

private struct DashboardSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title3.weight(.bold))
                Spacer()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if icon == "StatTrackerIconArtwork" {
                    Image("StatTrackerIconArtwork")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                } else {
                    Image(systemName: icon)
                }
            }
            .foregroundStyle(tint)
            .font(.headline)
            .frame(width: 18, height: 18)

            Text(value)
                .font(.system(.title2, design: .monospaced, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct MatchRow: View {
    let match: Match

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .foregroundStyle(.orange)
                .frame(width: 28, height: 28)
                .background(.orange.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("vs. \(match.opponent)")
                    .font(.headline)
                Text(match.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(scoreText)
                .font(.headline.monospacedDigit())
                .foregroundStyle(scoreColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var scoreText: String {
        match.result == .scheduled ? "Upcoming" : "\(match.goalsFor) - \(match.goalsAgainst)"
    }

    private var scoreColor: Color {
        switch match.result {
        case .win: .green
        case .loss: .red
        case .draw: .orange
        case .scheduled: .secondary
        }
    }
}

private struct EmptyDashboardCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Team.self, Player.self, Match.self, PlayerMatchStat.self], inMemory: true)
}
