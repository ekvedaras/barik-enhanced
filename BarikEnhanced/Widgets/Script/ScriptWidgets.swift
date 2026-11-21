import AppKit
import Combine
import Foundation

/// What one `script.<name>` widget shows. Shared by every screen's bar.
final class ScriptWidgetModel: ObservableObject {
    let name: String
    @Published private(set) var items: [ScriptItem] = []
    private(set) var settings: ScriptWidgetSettings?

    private var stream: ScriptStream?
    private var timer: Timer?
    private var polling = false
    private var pollAgain = false

    init(name: String) {
        self.name = name
    }

    var environment: [String: String] {
        (settings ?? ScriptWidgetSettings(command: "")).environment
    }

    func run(_ command: String) {
        ScriptProcess.runDetached(command, environment: environment)
    }

    /// Restarts the script when its settings changed; keeps the last items.
    func apply(_ settings: ScriptWidgetSettings?) {
        guard settings != self.settings else { return }
        stop()
        self.settings = settings
        guard let settings else {
            items = []
            return
        }

        switch settings.mode {
        case .stream:
            let stream = ScriptStream(name: name, settings: settings) { [weak self] line in
                DispatchQueue.main.async { self?.receive(line, source: "stream") }
            }
            self.stream = stream
            stream.start()
        case .poll:
            poll()
            if settings.interval > 0 {
                timer = Timer.scheduledTimer(withTimeInterval: settings.interval, repeats: true) {
                    [weak self] _ in self?.poll()
                }
            }
        }
    }

    func stop() {
        stream?.stop()
        stream = nil
        timer?.invalidate()
        timer = nil
    }

    func handle(event: String) {
        guard let settings, settings.mode == .poll, settings.events.contains(event) else { return }
        poll()
    }

    /// One run at a time; a request during a run queues exactly one more.
    func poll() {
        guard let settings, settings.mode == .poll else { return }
        guard !polling else {
            pollAgain = true
            return
        }
        polling = true
        DispatchQueue.global(qos: .utility).async { [weak self, name] in
            let result = ScriptProcess.poll(settings.command, environment: settings.environment)
            DispatchQueue.main.async {
                guard let self else { return }
                self.polling = false
                if let result {
                    if result.timedOut {
                        print("[script.\(name)] timed out after 10 s")
                    } else if result.status != 0 {
                        print("[script.\(name)] exited with status \(result.status), keeping the last items")
                    } else {
                        self.receive(result.output, source: "poll")
                    }
                }
                if self.pollAgain, self.settings == settings {
                    self.pollAgain = false
                    self.poll()
                }
            }
        }
    }

    private func receive(_ data: Data, source: String) {
        do {
            let document = try ScriptDocument.parse(data)
            if document.items != items { items = document.items }
        } catch {
            let text = String(decoding: data.prefix(200), as: UTF8.self)
            print("[script.\(name)] bad JSON from \(source), keeping the last items: \(error). Output: \(text)")
        }
    }
}

/// Owns every script widget's process, independent of how many bars draw it.
final class ScriptWidgets: NSObject {
    static let shared = ScriptWidgets()
    static let idPrefix = "script."

    private var models: [String: ScriptWidgetModel] = [:]
    private var configSubscription: AnyCancellable?

    func model(named name: String) -> ScriptWidgetModel {
        if let model = models[name] { return model }
        let model = ScriptWidgetModel(name: name)
        models[name] = model
        return model
    }

    func start() {
        configSubscription = ConfigManager.shared.$config
            .receive(on: DispatchQueue.main)
            .sink { [weak self] config in self?.apply(config) }

        let center = DistributedNotificationCenter.default()
        center.addObserver(
            self, selector: #selector(didReceiveTrigger(_:)),
            name: BarikPushChannel.trigger, object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(
            self, selector: #selector(didReceiveReload(_:)),
            name: BarikPushChannel.reload, object: nil, suspensionBehavior: .deliverImmediately)
    }

    func stopAll() {
        models.values.forEach { $0.stop() }
    }

    func trigger(_ event: String) {
        models.values.forEach { $0.handle(event: event) }
    }

    private func apply(_ config: Config) {
        var wanted: [String: ScriptWidgetSettings] = [:]
        for item in config.rootToml.widgets.displayed where item.id.hasPrefix(Self.idPrefix) {
            let name = String(item.id.dropFirst(Self.idPrefix.count))
            guard let settings = ScriptWidgetSettings(
                config: ConfigManager.shared.resolvedWidgetConfig(for: item),
                path: config.rootToml.script?.path)
            else {
                print("[\(item.id)] has no command in [widgets.\(item.id)]")
                continue
            }
            wanted[name] = settings
        }
        for (name, model) in models where wanted[name] == nil {
            model.apply(nil)
        }
        for (name, settings) in wanted {
            model(named: name).apply(settings)
        }
    }

    @objc private func didReceiveTrigger(_ notification: Notification) {
        guard let event = notification.object as? String else { return }
        print("[script] trigger \(event)")
        trigger(event)
    }

    @objc private func didReceiveReload(_ notification: Notification) {
        print("[script] reload requested")
        ConfigManager.shared.reloadConfig()
    }
}
