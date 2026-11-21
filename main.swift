import SwiftUI
import ApplicationServices
import ServiceManagement

let museBundleID = "com.meta.endo"

struct Upload: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let file: String
    let site: String
    var kind: String? = "upload"
}

// Card titles are Muse's permission questions, e.g. "Allow Vondu to share information with api.notion.com?".
struct Category {
    let key: String
    let label: String
    let defaultOn: Bool
    let pattern: String
}

let categories = [
    Category(key: "upload", label: "File uploads", defaultOn: true, pattern: #"to upload this file"#),
    Category(key: "web", label: "Web access and sharing", defaultOn: false,
             pattern: #"to access |to share information with |to read the web|read content from the web|research|web access"#),
    Category(key: "browser", label: "Form submits and clicks", defaultOn: false, pattern: #"to submit this form|to select “"#),
    Category(key: "connector", label: "App actions (email, Slack…)", defaultOn: false, pattern: #" in [^?]+\?$| to use "#),
]

// Money, bookings and sign-ins always ask, whatever the toggles say.
let neverPattern = #"(?i)purchase|check ?out|spend|order|pay|book|buy|subscri|donat|transfer|card|sign in|password"#

// Primary allow labels Muse renders; "Always allow…" and bulk "Allow all…" choices are never pressed.
let allowLabels: Set<String> = ["Allow once", "Allow", "Allow for this task", "Allow for this scheduled task",
                                "Allow for this artifact", "Allow for this space", "Allow for this idea",
                                "Allow for your Feed", "Allow all web access for this task"]

func isPrompt(_ title: String) -> Bool { title.hasPrefix("Allow ") && title.hasSuffix("?") }

func classify(_ title: String) -> String? {
    guard isPrompt(title), title.firstMatch(of: try! Regex(neverPattern)) == nil else { return nil }
    return categories.first { title.firstMatch(of: try! Regex($0.pattern)) != nil }?.key
}

func promptAction(_ title: String) -> String {
    if let m = title.firstMatch(of: try! Regex(#"^Allow .+? to (.+)\?$"#, as: (Substring, Substring).self)) { return String(m.1) }
    return String(title.dropFirst(6).dropLast())
}

enum Status { case active, paused, noAccess, museOff }

@MainActor final class Model: ObservableObject {
    @Published var trusted = AXIsProcessTrusted()
    @Published var museRunning = false
    @Published var paused = UserDefaults.standard.bool(forKey: "paused") {
        didSet { UserDefaults.standard.set(paused, forKey: "paused") }
    }
    @Published var enabled: Set<String> = Set(categories.filter { c in
        UserDefaults.standard.object(forKey: "allow." + c.key) as? Bool
            ?? (c.key == "web" ? UserDefaults.standard.bool(forKey: "allowSensitive") : c.defaultOn)
    }.map(\.key)) {
        didSet { for c in categories { UserDefaults.standard.set(enabled.contains(c.key), forKey: "allow." + c.key) } }
    }
    @Published var showTypes = false
    @Published var session = 0
    @Published var total = UserDefaults.standard.integer(forKey: "total")
    @Published var recent: [Upload] = {
        guard let d = UserDefaults.standard.data(forKey: "recent") else { return [] }
        return (try? JSONDecoder().decode([Upload].self, from: d)) ?? []
    }()
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled
    private var scanning = false
    private var lastClick = Date.distantPast

    var status: Status {
        if !trusted { return .noAccess }
        if paused { return .paused }
        return museRunning ? .active : .museOff
    }

    init() {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task { @MainActor in self.tick() }
        }
    }

    func tick() {
        trusted = AXIsProcessTrusted()
        let app = NSRunningApplication.runningApplications(withBundleIdentifier: museBundleID).first
        museRunning = app != nil
        guard let pid = app?.processIdentifier, trusted, !paused, !scanning,
              Date().timeIntervalSince(lastClick) > 2 else { return }
        scanning = true
        let enabled = enabled
        DispatchQueue.global(qos: .utility).async {
            let hit = scanAndAllow(pid, enabled)
            DispatchQueue.main.async {
                self.scanning = false
                if let hit { self.record(hit) }
            }
        }
    }

    private func record(_ u: Upload) {
        lastClick = u.date
        session += 1
        total += 1
        recent = Array(([u] + recent).prefix(20))
        UserDefaults.standard.set(total, forKey: "total")
        UserDefaults.standard.set(try? JSONEncoder().encode(recent), forKey: "recent")
    }

    func setLaunchAtLogin(_ on: Bool) {
        try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

// MARK: Accessibility

private func attr(_ e: AXUIElement, _ name: String) -> AnyObject? {
    var v: AnyObject?
    return AXUIElementCopyAttributeValue(e, name as CFString, &v) == .success ? v : nil
}

private func strings(_ e: AXUIElement) -> [String] {
    [kAXValueAttribute, kAXTitleAttribute, kAXDescriptionAttribute].compactMap { attr(e, $0) as? String }
}

func parseUpload(_ detail: String) -> (file: String, site: String)? {
    guard let m = try? Regex(#"upload (a file|.+?\.\w+) to (.+?)(?:\. This task|$)"#, as: (Substring, Substring, Substring).self).firstMatch(in: detail)
    else { return nil }
    let rest = String(m.2)
    if let d = try? Regex(#"([A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,})\b"#, as: (Substring, Substring).self).firstMatch(in: rest) {
        return (String(m.1), String(d.1))
    }
    // No domain in the text: the agent named the site, e.g. "to Rubrik to apply…".
    let name = rest.components(separatedBy: " to apply").first!.components(separatedBy: " for ").first!
    return (String(m.1), name.hasPrefix("the ") ? String(name.dropFirst(4)) : name)
}

// ponytail: debug log for prompts whose site/file couldn't be read; drop once parsing is solid.
func logUnparsed(_ kind: String, _ text: [String]) {
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/MuseAutoAllow.log")
    let line = "\(Date()) [\(kind)] " + text.map { $0.replacingOccurrences(of: "\n", with: " ") }.joined(separator: " | ") + "\n"
    if let h = try? FileHandle(forWritingTo: url) {
        h.seekToEndOfFile(); h.write(Data(line.utf8)); try? h.close()
    } else {
        try? line.write(to: url, atomically: true, encoding: .utf8)
    }
}

nonisolated func scanAndAllow(_ pid: pid_t, _ enabled: Set<String>) -> Upload? {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, 1)
    for window in (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? [] {
        // Breadth-first so the approval card is reached before a long chat history eats the budget.
        var nodes: [(el: AXUIElement, parent: Int, text: [String])] = [(window, -1, strings(window))]
        var i = 0
        while i < nodes.count, nodes.count < 8000 {
            for c in (attr(nodes[i].el, kAXChildrenAttribute) as? [AXUIElement]) ?? [] { nodes.append((c, i, strings(c))) }
            i += 1
        }
        func ancestors(_ n: Int) -> [Int] {
            var out: [Int] = [], k = n
            while k >= 0 { out.append(k); k = nodes[k].parent }
            return out
        }
        func subtreeText(_ root: Int) -> [String] {
            nodes.indices.filter { ancestors($0).contains(root) }.flatMap { nodes[$0].text }
        }
        func isButton(_ n: Int) -> Bool { (attr(nodes[n].el, kAXRoleAttribute) as? String) == kAXButtonRole }
        let allows = nodes.indices.filter { !allowLabels.isDisjoint(with: nodes[$0].text) && isButton($0) }
        if allows.isEmpty { continue }
        let denies = nodes.indices.filter { nodes[$0].text.contains { $0.hasPrefix("Deny") } && isButton($0) }
        for t in nodes.indices {
            guard let title = nodes[t].text.first(where: { classify($0).map(enabled.contains) == true }) else { continue }
            let up = ancestors(t)
            for a in allows {
                // The card is the smallest container holding both the prompt title and this button.
                let mine = Set(ancestors(a))
                guard let card = up.first(where: mine.contains) else { continue }
                // Another allow button inside it could belong to a different request: don't guess.
                guard allows.filter({ ancestors($0).contains(card) }).count == 1,
                      denies.contains(where: { ancestors($0).contains(card) }) else { continue }
                let text = subtreeText(card)
                // A stray title (e.g. quoted in chat) can pair with another request's card: every prompt in it must be allowed.
                guard text.filter(isPrompt).allSatisfy({ classify($0).map(enabled.contains) == true }) else { continue }
                guard AXUIElementPerformAction(nodes[a].el, kAXPressAction as CFString) == .success else { return nil }
                let key = classify(title)!
                if key != "upload" {
                    return Upload(date: Date(), file: categories.first { $0.key == key }!.label, site: promptAction(title), kind: key)
                }
                let parsed = text.lazy.filter { $0.contains("wants to upload") }.compactMap(parseUpload).first
                if parsed == nil { logUnparsed(key, text) }
                return Upload(date: Date(), file: parsed?.file ?? "file", site: parsed?.site ?? "unknown site", kind: key)
            }
        }
    }
    return nil
}

// MARK: Icon

let menuMark = Bundle.main.image(forResource: "MenuMark")

func menuIcon(_ status: Status) -> NSImage {
    let img = NSImage(size: NSSize(width: 25, height: 16), flipped: false) { _ in
        let ctx = NSGraphicsContext.current!
        menuMark?.draw(in: NSRect(x: 0, y: 0, width: 22, height: 16))

        let c = NSPoint(x: 20.2, y: 5.2), r = 4.6, gap = 2.4
        ctx.compositingOperation = .clear
        NSBezierPath(ovalIn: NSRect(x: c.x - r - gap, y: c.y - r - gap, width: 2 * (r + gap), height: 2 * (r + gap))).fill()
        ctx.compositingOperation = .sourceOver
        NSColor.black.set()
        let disc = NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        if status == .museOff {
            disc.lineWidth = 1.4; disc.stroke(); return true
        }
        disc.fill()
        ctx.compositingOperation = .clear
        let g = NSBezierPath()
        g.lineWidth = 1.5
        g.lineCapStyle = .round
        g.lineJoinStyle = .round
        switch status {
        case .active:
            g.move(to: NSPoint(x: c.x - 2.2, y: c.y)); g.line(to: NSPoint(x: c.x - 0.6, y: c.y - 1.6)); g.line(to: NSPoint(x: c.x + 2.2, y: c.y + 1.7))
        case .paused:
            g.move(to: NSPoint(x: c.x - 1.2, y: c.y - 2)); g.line(to: NSPoint(x: c.x - 1.2, y: c.y + 2))
            g.move(to: NSPoint(x: c.x + 1.2, y: c.y - 2)); g.line(to: NSPoint(x: c.x + 1.2, y: c.y + 2))
        case .noAccess:
            g.move(to: NSPoint(x: c.x, y: c.y + 2.3)); g.line(to: NSPoint(x: c.x, y: c.y - 0.3))
            g.move(to: NSPoint(x: c.x, y: c.y - 2.2)); g.line(to: NSPoint(x: c.x, y: c.y - 2.15))
        case .museOff: break
        }
        g.stroke()
        ctx.compositingOperation = .sourceOver
        return true
    }
    img.isTemplate = true
    return img
}

// MARK: UI

struct Panel: View {
    @ObservedObject var m: Model

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(nsImage: menuIcon(m.status))
                    Text("MuseAutoAllow").font(.headline)
                    Spacer()
                    pill
                }
                .padding(.horizontal, 12)

                HStack(spacing: 10) {
                    stat("This session", m.session)
                    stat("All time", m.total)
                }

                if !m.trusted {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Needs Accessibility access to press Muse's buttons.")
                            .font(.callout)
                        Button("Open Accessibility Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                        .buttonStyle(.glassProminent)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular.tint(.orange.opacity(0.25)), in: .rect(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent approvals").font(.caption).foregroundStyle(.secondary)
                    if m.recent.isEmpty {
                        Text("Nothing allowed yet").font(.callout).foregroundStyle(.tertiary)
                    }
                    ForEach(m.recent.prefix(6)) { u in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(u.site).font(.callout.weight(.medium)).lineLimit(1)
                                Text(u.file).font(.caption).foregroundStyle((u.kind ?? "upload") != "upload" ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary)).lineLimit(1)
                            }
                            Spacer()
                            Text(u.date, style: .time)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))

                VStack(spacing: 10) {
                    row("Pause auto-allow", $m.paused)
                    Button {
                        withAnimation(.snappy) { m.showTypes.toggle() }
                    } label: {
                        HStack {
                            Text("Auto-allow").font(.callout)
                            Spacer()
                            Text("\(m.enabled.count) of \(categories.count) on").font(.caption).foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                .rotationEffect(.degrees(m.showTypes ? 90 : 0))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    if m.showTypes {
                        VStack(spacing: 10) {
                            ForEach(categories, id: \.key) { c in
                                row(c.label, Binding(get: { m.enabled.contains(c.key) },
                                                     set: { if $0 { m.enabled.insert(c.key) } else { m.enabled.remove(c.key) } }))
                            }
                            Text("Purchases, checkout and sign-ins always ask.")
                                .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.leading, 12)
                    }
                    row("Launch at login", Binding(get: { m.launchAtLogin }, set: { m.setLaunchAtLogin($0) }))
                }
                .padding(12)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))

                HStack {
                    Text("v" + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")).font(.caption2).foregroundStyle(.tertiary)
                    Spacer()
                    Button("Quit") { NSApp.terminate(nil) }.buttonStyle(.glass).controlSize(.small)
                }
                .padding(.leading, 12)
            }
            .padding(12)
        }
        .frame(width: 310)
    }

    private var pill: some View {
        let (text, color): (String, Color) = switch m.status {
        case .active: ("Active", .green)
        case .paused: ("Paused", .yellow)
        case .noAccess: ("No access", .orange)
        case .museOff: ("Muse not running", .gray)
        }
        return HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).font(.caption.weight(.medium))
        }
        .padding(.horizontal, 9).padding(.vertical, 4)
        .glassEffect(.regular.tint(color.opacity(0.2)), in: .capsule)
    }

    private func row(_ label: String, _ on: Binding<Bool>) -> some View {
        HStack {
            Text(label).font(.callout)
            Spacer()
            Toggle(label, isOn: on).labelsHidden().toggleStyle(.switch).controlSize(.small)
        }
    }

    private func stat(_ label: String, _ n: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(n)").font(.system(size: 26, weight: .semibold, design: .rounded)).contentTransition(.numericText())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

#if !SELFTEST
@main struct MuseAutoAllowApp: App {
    @StateObject private var m = Model()

    var body: some Scene {
        MenuBarExtra {
            Panel(m: m)
        } label: {
            Image(nsImage: menuIcon(m.status))
        }
        .menuBarExtraStyle(.window)
    }
}
#endif
