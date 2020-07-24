//
//  Models.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 12/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import RealmSwift
import SwiftUI

class Playlist: Object, Identifiable, Codable {
    @objc dynamic var name: String!

    convenience init(name: String) {
        self.init()
        self.name = name
    }

    override class func primaryKey() -> String? {
        return "name"
    }
}

class Track: Object, Identifiable, Codable {
    @objc dynamic var id: String!
    @objc dynamic var name: String!
    var playlists = RealmSwift.List<Playlist>()

    /// Track name for UI label
    var uiName: String {
        return name.replacingOccurrences(of: ".mp3", with: "")
    }

    /// Property for controlling UI selecting row state
    var isTrackSelected: Bool = false

    /// Playlist names for UI label
    var uiPlaylists: String {
        var value = self.playlists.reduce("") { result, playlist -> String in
            result + playlist.name + " - "
        }
        guard !value.isEmpty else { return "_" }

        (0...2).forEach { _ in value.removeLast() }

        return value
    }

    convenience init(id: String, name: String) {
        self.init()
        self.id = id
        self.name = name
    }

    override class func primaryKey() -> String? {
        return "id"
    }

    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Array where Element == Track {
    enum TrackDirection {
        case next, previous
    }

    func getTrack(current: Track, direction: TrackDirection) -> Track? {
        guard let index = firstIndex(where: { $0 == current }) else {
            return nil
        }
        let requiredIndex = direction == .next ? self.index(after: index) : self.index(before: index)

        guard requiredIndex >= 0 else {
            return last
        }

        return indices.contains(requiredIndex) ? self[requiredIndex] : first
    }
}
