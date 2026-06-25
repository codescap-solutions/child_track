import Foundation
import os.log

class NativeBackgroundSyncManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    static let shared = NativeBackgroundSyncManager()
    
    private let log = OSLog(subsystem: "com.truenyx.naviq", category: "NativeBackgroundSync")
    private let appGroupID = "group.com.truenyx.naviq"
    private let kGeofenceQueue = "com.truenyx.naviq.geofence_queue"
    private let kAuthToken = "com.truenyx.naviq.auth_token"
    private let kApiBaseUrl = "com.truenyx.naviq.api_base_url"
    private let kChildId = "com.truenyx.naviq.child_id"
    
    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }
    
    private var backgroundSession: URLSession!
    private var isSyncing = false
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.truenyx.naviq.background_geofence_sync")
        config.sharedContainerIdentifier = appGroupID
        config.sessionSendsLaunchEvents = true
        config.waitsForConnectivity = true
        self.backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func enqueue(_ event: GeofenceEvent) {
        guard let defaults = sharedDefaults else { return }
        var queue = getQueue()
        queue.append(event)
        if let encoded = try? JSONEncoder().encode(queue) {
            defaults.set(encoded, forKey: kGeofenceQueue)
            defaults.synchronize()
        }
        os_log("📥 Enqueued geofence event: %{public}@ for %{public}@", log: log, type: .info, event.type, event.geofenceId)
    }
    
    func getQueue() -> [GeofenceEvent] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: kGeofenceQueue),
              let queue = try? JSONDecoder().decode([GeofenceEvent].self, from: data) else {
            return []
        }
        return queue
    }
    
    func clearQueue() {
        sharedDefaults?.removeObject(forKey: kGeofenceQueue)
        sharedDefaults?.synchronize()
    }
    
    func triggerSync() {
        guard !isSyncing else { return }
        let queue = getQueue()
        guard !queue.isEmpty else { return }
        
        guard let defaults = sharedDefaults,
              let token = defaults.string(forKey: kAuthToken), !token.isEmpty,
              let childId = defaults.string(forKey: kChildId), !childId.isEmpty else {
            os_log("⚠️ Cannot sync geofence events: missing auth credentials", log: log, type: .error)
            return
        }
        
        let apiBase = defaults.string(forKey: kApiBaseUrl) ?? "https://naviq-server.codescap.com/api/v1/"
        let urlString = "\(apiBase)child/geofence-event"
        
        guard let url = URL(string: urlString) else { return }
        
        isSyncing = true
        
        // Batch upload payload
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Build the request body mapping
        let payload: [String: Any] = [
            "childId": childId,
            "events": queue.map { event -> [String: Any] in
                return [
                    "type": event.type,
                    "geofenceId": event.geofenceId,
                    "timestamp": event.timestamp,
                    "lat": event.lat,
                    "lng": event.lng
                ]
            }
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            isSyncing = false
            return
        }
        
        // Write body to temporary file since background tasks require file transfers
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".json")
        try? httpBody.write(to: fileURL)
        
        let uploadTask = backgroundSession.uploadTask(with: request, fromFile: fileURL)
        uploadTask.resume()
        os_log("📤 Started background upload task for %d geofence events", log: log, type: .info, queue.count)
    }
    
    // MARK: - URLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        isSyncing = false
        if let error = error {
            os_log("❌ Background geofence upload failed: %{public}@", log: log, type: .error, error.localizedDescription)
        } else {
            let response = task.response as? HTTPURLResponse
            let code = response?.statusCode ?? 0
            if code >= 200 && code < 300 {
                os_log("✅ Background geofence upload succeeded (status code: %d)", log: log, type: .info, code)
                clearQueue()
            } else {
                os_log("⚠️ Background geofence upload rejected by server: %d", log: log, type: .error, code)
            }
        }
    }
}
