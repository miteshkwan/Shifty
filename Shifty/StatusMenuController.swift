//
//  StatusMenuController.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa
import MASShortcut
import AXSwift
import SwiftLog

class StatusMenuController: NSObject, NSMenuDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var powerMenuItem: NSMenuItem!
    @IBOutlet weak var sliderMenuItem: NSMenuItem!
    @IBOutlet weak var descriptionMenuItem: NSMenuItem!
    @IBOutlet weak var disableAppMenuItem: NSMenuItem!
    @IBOutlet weak var disableDomainMenuItem: NSMenuItem!
    @IBOutlet weak var disableSubdomainMenuItem: NSMenuItem!
    @IBOutlet weak var disableHourMenuItem: NSMenuItem!
    @IBOutlet weak var disableCustomMenuItem: NSMenuItem!
    @IBOutlet weak var preferencesMenuItem: NSMenuItem!
    @IBOutlet weak var quitMenuItem: NSMenuItem!
    @IBOutlet weak var sliderView: SliderView!
    @IBOutlet weak var sunIcon: NSImageView! {
        didSet {
            sunIcon.image?.isTemplate = true
        }
    }
    @IBOutlet weak var moonIcon: NSImageView! {
        didSet {
            moonIcon.image?.isTemplate = true
        }
    }

    var preferencesWindow: NSWindowController!
    var prefGeneral: PrefGeneralViewController!
    var prefShortcuts: PrefShortcutsViewController!
    var customTimeWindow: CustomTimeWindow!

    let calendar = NSCalendar(identifier: .gregorian)!

    //MARK: Menu life cycle

    override func awakeFromNib() {
        Log.logger.directory = "~/Library/Logs/Shifty"
        #if DEBUG
            Log.logger.name = "Shifty-debug"
        #else
            Log.logger.name = "Shifty"
        #endif
        //Edit printToConsole parameter in Edit Scheme > Run > Arguments > Environment Variables
        Log.logger.printToConsole = ProcessInfo.processInfo.environment["print_log"] == "true"

        statusMenu.delegate = self
        customTimeWindow = CustomTimeWindow()

        let prefWindow = (NSApplication.shared.delegate as? AppDelegate)?.preferenceWindowController
        prefGeneral = prefWindow?.viewControllers.flatMap { childViewController in
            return childViewController as? PrefGeneralViewController
        }.first
        prefShortcuts = prefWindow?.viewControllers.flatMap { childViewController in
            return childViewController as? PrefShortcutsViewController
        }.first

        descriptionMenuItem.isEnabled = false
        sliderMenuItem.view = sliderView

        disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
        disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
        preferencesMenuItem.title = NSLocalizedString("menu.preferences", comment: "Preferences...")
        quitMenuItem.title = NSLocalizedString("menu.quit", comment: "Quit Shifty")

        sliderView.sliderValueChanged = { (sliderValue) in

        }

        sliderView.sliderEnabled = {

        }

        (NSApp.delegate as? AppDelegate)?.statusItemClicked = {

        }

        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.apple.accessibility.api"), object: nil, queue: nil) { _ in
            logw("Accessibility permissions changed: \(UIElement.isProcessTrusted(withPrompt: false))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    if UIElement.isProcessTrusted(withPrompt: false) {
                        UserDefaults.standard.set(true, forKey: Keys.isWebsiteControlEnabled)
                    } else {
                        UserDefaults.standard.set(false, forKey: Keys.isWebsiteControlEnabled)
                    }
                })
        }

        prefShortcuts.bindShortcuts()
    }

    func menuWillOpen(_: NSMenu) {
        assignKeyboardShortcutToMenuItem(powerMenuItem, userDefaultsKey: Keys.toggleNightShiftShortcut)
        assignKeyboardShortcutToMenuItem(disableAppMenuItem, userDefaultsKey: Keys.disableAppShortcut)
        assignKeyboardShortcutToMenuItem(disableDomainMenuItem, userDefaultsKey: Keys.disableDomainShortcut)
        assignKeyboardShortcutToMenuItem(disableSubdomainMenuItem, userDefaultsKey: Keys.disableSubdomainShortcut)
        assignKeyboardShortcutToMenuItem(disableHourMenuItem, userDefaultsKey: Keys.disableHourShortcut)
        assignKeyboardShortcutToMenuItem(disableCustomMenuItem, userDefaultsKey: Keys.disableCustomShortcut)

        Event.menuOpened.record()
    }

    func assignKeyboardShortcutToMenuItem(_ menuItem: NSMenuItem, userDefaultsKey: String) {
        if let data = UserDefaults.standard.value(forKey: userDefaultsKey),
            let shortcut = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as? MASShortcut {
            let flags = NSEvent.ModifierFlags.init(rawValue: shortcut.modifierFlags)
            menuItem.keyEquivalentModifierMask = flags
            menuItem.keyEquivalent = shortcut.keyCodeString.lowercased()
        } else {
            menuItem.keyEquivalentModifierMask = []
            menuItem.keyEquivalent = ""
        }
    }


    //MARK: Handle states

    //MARK: User Interaction

    @IBAction func power(_ sender: Any) {
        if NightShiftManager.isNightShiftEnabled {
            NightShiftManager.respond(to: .userDisabledNightShift)
        } else {
            NightShiftManager.respond(to: .userEnabledNightShift)
        }
    }

    @IBAction func disableForApp(_ sender: Any) {
        guard let currentAppBundleIdentifier = RuleManager.currentApp?.bundleIdentifier else {
            return
        }
        // If we're adding a new app to the disabled list
        if !RuleManager.disabledApps.contains(currentAppBundleIdentifier) {
            RuleManager.disabledApps.insert(currentAppBundleIdentifier)
        } else { // We're removing an app from the disabled list
            RuleManager.disabledApps.remove(currentAppBundleIdentifier)
        }
    }

    @IBAction func disableForDomain(_ sender: Any) {

    }

    @IBAction func disableForSubdomain(_ sender: Any) {

    }

    @IBAction func disableHour(_ sender: Any) {

    }

    @IBAction func disableCustomTime(_ sender: Any) {

    }

    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        (NSApp.delegate as? AppDelegate)?.preferenceWindowController.showWindow(sender)

        Event.preferencesWindowOpened.record()
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
//        NightShiftManager.respond(to: .nightShiftDisableTimerEnded)
//        NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)

        Event.quitShifty.record()
        NotificationCenter.default.post(name: .terminateApp, object: self)
    }


    //MARK: Helper functions
}
