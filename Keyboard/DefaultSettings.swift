//
//  DefaultSettings.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

/// The keyboard's settings, shown in place of the keys when the toolbar's
/// settings button is tapped. Laid out like the system's Settings app: grouped
/// rows with a switch each, and any note beneath its group.
class DefaultSettings: ExtraView, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView(frame: CGRect.zero, style: .insetGrouped)
    let backButton = UIButton(type: .system)
    let titleLabel = UILabel()

    override var darkMode: Bool {
        didSet {
            self.updateAppearance(darkMode)
        }
    }

    // TODO: these probably don't belong here, and also need to be localized
    var settingsList: [(String, [String])] {
        get {
            return [
                ("General Settings", [kAutoCapitalization, kPeriodShortcut, kKeyboardClicks]),
                ("Extra Settings", [kSmallLowercase])
            ]
        }
    }
    var settingsNames: [String:String] {
        get {
            return [
                kAutoCapitalization: "Auto-Capitalization",
                kPeriodShortcut:  "“.” Shortcut",
                kKeyboardClicks: "Keyboard Clicks",
                kSmallLowercase: "Show Lowercase Keys"
            ]
        }
    }
    var settingsNotes: [String: String] {
        get {
            return [
                kSmallLowercase: "Shows lowercase letters on the keys while Shift is off, as the system keyboard does. Turn this off to always show capitals."
            ]
        }
    }

    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        self.setUpViews()
        self.updateAppearance(darkMode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("loading from nib not supported")
    }

    func setUpViews() {
        // A round button with a chevron, like the back buttons of iOS 26.
        var configuration: UIButton.Configuration
        if #available(iOS 26.0, *) {
            configuration = UIButton.Configuration.glass()
        }
        else {
            configuration = UIButton.Configuration.gray()
        }
        configuration.cornerStyle = .capsule
        configuration.image = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        self.backButton.configuration = configuration
        self.backButton.accessibilityLabel = "Back to Keyboard"
        self.backButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.backButton)

        self.titleLabel.text = "Settings"
        self.titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.titleLabel)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.allowsSelection = false
        // The keyboard's own backdrop shows around the groups.
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.tableView)

        NSLayoutConstraint.activate([
            self.backButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            self.backButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            self.backButton.widthAnchor.constraint(equalToConstant: 40),
            self.backButton.heightAnchor.constraint(equalToConstant: 40),

            self.titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.titleLabel.centerYAnchor.constraint(equalTo: self.backButton.centerYAnchor),

            self.tableView.topAnchor.constraint(equalTo: self.backButton.bottomAnchor, constant: 4),
            self.tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.settingsList.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settingsList[section].1.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.settingsList[section].0
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let notes = self.settingsList[section].1.compactMap { self.settingsNotes[$0] }
        return (notes.isEmpty ? nil : notes.joined(separator: "\n\n"))
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let key = self.settingsList[indexPath.section].1[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = self.settingsNames[key]
        cell.contentConfiguration = content

        let toggle: UISwitch
        if let existing = cell.accessoryView as? UISwitch {
            toggle = existing
        }
        else {
            toggle = UISwitch()
            toggle.addTarget(self, action: #selector(DefaultSettings.toggleSetting(_:)), for: UIControl.Event.valueChanged)
            cell.accessoryView = toggle
        }
        toggle.isOn = UserDefaults.standard.bool(forKey: key)
        toggle.accessibilityIdentifier = key

        return cell
    }

    // The panel follows the keys' appearance, which can be dark in a light app
    // when the field asks for a dark keyboard.
    func updateAppearance(_ dark: Bool) {
        self.overrideUserInterfaceStyle = (dark ? .dark : .light)
        self.titleLabel.textColor = UIColor.label
        self.backButton.tintColor = UIColor.label
    }

    @objc func toggleSetting(_ sender: UISwitch) {
        if let key = sender.accessibilityIdentifier {
            UserDefaults.standard.set(sender.isOn, forKey: key)
        }
    }
}
