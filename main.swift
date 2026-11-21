import SwiftUI
import ApplicationServices
import ServiceManagement

let museBundleID = "com.meta.endo"

struct Upload: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let file: String
    let site: String
}

enum Status { case active, paused, noAccess, museOff }

@MainActor final class Model: ObservableObject {
    @Published var trusted = AXIsProcessTrusted()
    @Published var museRunning = false
    @Published var paused = UserDefaults.standard.bool(forKey: "paused") {
        didSet { UserDefaults.standard.set(paused, forKey: "paused") }
    }
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
        DispatchQueue.global(qos: .utility).async {
            let hit = scanAndAllow(pid)
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

nonisolated func scanAndAllow(_ pid: pid_t) -> Upload? {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, 1)
    for window in (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? [] {
        var texts: [String] = []
        var allow: AXUIElement?
        var budget = 8000
        func walk(_ e: AXUIElement, _ depth: Int) {
            budget -= 1
            guard budget > 0, depth < 80 else { return }
            let s = strings(e)
            texts += s
            if (attr(e, kAXRoleAttribute) as? String) == kAXButtonRole, s.contains("Allow once") {
                allow = e
            }
            for c in (attr(e, kAXChildrenAttribute) as? [AXUIElement]) ?? [] { walk(c, depth + 1) }
        }
        walk(window, 0)
        guard let allow, texts.contains(where: { $0.contains("to upload this file") }) else { continue }
        guard AXUIElementPerformAction(allow, kAXPressAction as CFString) == .success else { return nil }
        let detail = texts.first { $0.contains("wants to upload") } ?? ""
        let m = try? Regex(#"upload (.+?) to (\S+?)\.(?:\s|$)"#, as: (Substring, Substring, Substring).self).firstMatch(in: detail)
        return Upload(date: Date(), file: m.map { String($0.1) } ?? "file", site: m.map { String($0.2) } ?? "unknown site")
    }
    return nil
}

// MARK: Icon

func menuIcon(_ status: Status) -> NSImage {
    let img = NSImage(size: NSSize(width: 20, height: 16), flipped: false) { _ in
        let m = NSBezierPath()
        m.lineWidth = 1.9
        m.lineCapStyle = .round
        m.lineJoinStyle = .round
        m.move(to: NSPoint(x: 2, y: 2.5))
        m.line(to: NSPoint(x: 2, y: 8.5))
        m.curve(to: NSPoint(x: 6.75, y: 8.5), controlPoint1: NSPoint(x: 2, y: 13), controlPoint2: NSPoint(x: 6.75, y: 13))
        m.line(to: NSPoint(x: 6.75, y: 2.5))
        m.move(to: NSPoint(x: 6.75, y: 8.5))
        m.curve(to: NSPoint(x: 11.5, y: 8.5), controlPoint1: NSPoint(x: 6.75, y: 13), controlPoint2: NSPoint(x: 11.5, y: 13))
        m.line(to: NSPoint(x: 11.5, y: 2.5))
        m.stroke()

        let b = NSBezierPath()
        b.lineWidth = 1.7
        b.lineCapStyle = .round
        b.lineJoinStyle = .round
        switch status {
        case .active:
            b.move(to: NSPoint(x: 13.5, y: 5.5)); b.line(to: NSPoint(x: 15.3, y: 3.5)); b.line(to: NSPoint(x: 18.5, y: 8))
        case .paused:
            b.move(to: NSPoint(x: 14.5, y: 3)); b.line(to: NSPoint(x: 14.5, y: 8))
            b.move(to: NSPoint(x: 17.5, y: 3)); b.line(to: NSPoint(x: 17.5, y: 8))
        case .noAccess:
            b.move(to: NSPoint(x: 16, y: 6)); b.line(to: NSPoint(x: 16, y: 11))
            NSBezierPath(ovalIn: NSRect(x: 15.1, y: 2, width: 1.8, height: 1.8)).fill()
        case .museOff:
            NSBezierPath(ovalIn: NSRect(x: 14.5, y: 3, width: 3.5, height: 3.5)).stroke()
        }
        b.stroke()
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
                .padding(.horizontal, 4)

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
                    Text("Recent uploads").font(.caption).foregroundStyle(.secondary)
                    if m.recent.isEmpty {
                        Text("Nothing allowed yet").font(.callout).foregroundStyle(.tertiary)
                    }
                    ForEach(m.recent.prefix(6)) { u in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(u.site).font(.callout.weight(.medium)).lineLimit(1)
                                Text(u.file).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Text(u.date, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))

                VStack(spacing: 8) {
                    Toggle("Pause auto-allow", isOn: $m.paused)
                    Toggle("Launch at login", isOn: Binding(get: { m.launchAtLogin }, set: { m.setLaunchAtLogin($0) }))
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(12)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))

                HStack {
                    Text("Only upload prompts are approved.").font(.caption2).foregroundStyle(.tertiary)
                    Spacer()
                    Button("Quit") { NSApp.terminate(nil) }.buttonStyle(.glass).controlSize(.small)
                }
                .padding(.horizontal, 4)
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
