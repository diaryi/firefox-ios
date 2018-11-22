/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import JavaScriptCore
import Shared
import Storage
import XCGLogger

private let log = Logger.browserLogger

class DocumentServicesHelper: TabEventHandler {
    private var tabObservers: TabObservers!
    private let prefs: Prefs

    private lazy var context: JSContext = {
        let context: JSContext = JSContext()

        context.exceptionHandler = { context, exception in
            if let exception = exception {
                log.error("DocumentServices.js: \(exception)")
            }
        }

        let name = "DocumentServices"
        guard let path = Bundle.main.path(forResource: name, ofType: "js"),
            let jsFile = try? String(contentsOfFile: path, encoding: .utf8) else {
            log.error("DocumentServices are unavailable due to missing or corrupt JS file")
            return context
        }

        context.evaluateScript("var __firefox__;")
        context.evaluateScript(jsFile)

        return context
    }()

    init(_ prefs: Prefs) {
        self.prefs = prefs
        self.tabObservers = registerFor(
            .didLoadPageMetadata,
            queue: .main)
    }

    deinit {
        unregister(tabObservers)
    }

    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        guard let firefox = context.objectForKeyedSubscript("__firefox__"),
            let isConfigured = firefox.objectForKeyedSubscript("isConfigured"),
            isConfigured.isBoolean && isConfigured.toBool() else {
            log.error("Unable to do anything without a firefox object.")
            return
        }

        log.info("We have a firefox object")
    }
}
