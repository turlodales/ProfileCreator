//
//  ValueImportProcessorSystemExtensionPolicyRemovable.swift
//  ProfileCreator
//
//  Created by Will Yu on 10/10/22.
//  Copyright © 2022 Will Yu. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ValueImportProcessorSystemExtensionPolicyRemovable: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.syspolicy.system-extension-policy.RemovableSystemExtensions")
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // Verify it's a system extension bundle
        guard
            let fileExtension = self.fileURL?.pathExtension,
            let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeUnretainedValue() as String?,
            let systemExtensionUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "systemextension" as CFString, nil)?.takeUnretainedValue() as String?,
            fileUTI == systemExtensionUTI else {
                throw ValueImportError("Only system extensions (.systemextension) are allowed in this payload.")
        }

        guard
            let fileURL = self.fileURL,
            let systemExtensionBundle = Bundle(url: fileURL) else {
                throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" does not seem to be a valid system extension.")
        }

        var value = [String: Any]()
        var bundleIdentifiers = [String]()
        
        guard let teamIdentifier = systemExtensionBundle.teamIdentifier else {
            throw ValueImportError("The system extension: \"\(systemExtensionBundle.bundleDisplayName ?? systemExtensionBundle.bundleURL.lastPathComponent)\" does not seem to be signed. No team identifier could be found.")
        }

        guard let bundleIdentifier = systemExtensionBundle.bundleIdentifier else {
            throw ValueImportError("The system extension: \"\(systemExtensionBundle.bundleDisplayName ?? systemExtensionBundle.bundleURL.lastPathComponent)\" does not seem to be a valid system extension. No bundle identifier could be found.")
        }

        if let currentValue = toCurrentValue as? [[String: Any]] {
            if let existingDict = currentValue.first(where: { $0[ManifestKeyPlaceholder.key] as? String == teamIdentifier }) {
                value = existingDict
                bundleIdentifiers = existingDict[ManifestKeyPlaceholder.value] as? [String] ?? [String]()
            }
        }

        if value.isEmpty {
            value[ManifestKeyPlaceholder.key] = teamIdentifier
        }

        if !bundleIdentifiers.contains(bundleIdentifier) {
            bundleIdentifiers.append(bundleIdentifier)
        }

        value[ManifestKeyPlaceholder.value] = bundleIdentifiers

        if var currentValue = toCurrentValue as? [[String: Any]] {
            if let index = currentValue.firstIndex(where: { $0[ManifestKeyPlaceholder.key] as? String == value[ManifestKeyPlaceholder.key] as? String }) {
                currentValue[index] = value
            } else {
                currentValue.append(value)
            }
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }
}
