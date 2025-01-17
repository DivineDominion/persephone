//
//  MPDActions.swift
//  Persephone
//
//  Created by Daniel Barber on 2019/4/30.
//  Copyright © 2019 Dan Barber. All rights reserved.
//

import ReSwift

struct MPDConnectAction: Action {}
struct MPDDisconnectAction: Action {}

struct MPDPlayPauseAction: Action {}
struct MPDStopAction: Action {}
struct MPDNextTrackAction: Action {}
struct MPDPrevTrackAction: Action {}

struct MPDClearQueue: Action {}

struct MPDMoveSongInQueue: Action {
  let oldQueuePos: Int
  let newQueuePos: Int
}

struct MPDAddSongToQueue: Action {
  let songUri: String
  let queuePos: Int
}

struct MPDAppendTrack: Action {
  let song: MPDClient.MPDSong
}

struct MPDRemoveTrack: Action {
  let queuePos: Int
}

struct MPDPlayTrack: Action {
  let queuePos: Int
}

struct MPDPlayAlbum: Action {
  let album: MPDClient.MPDAlbum
}

struct MPDSeekCurrentSong: Action {
  let timeInSeconds: Float
}

struct MPDUpdateDatabaseAction: Action {}

struct MPDSetShuffleAction: Action {
  let shuffleState: Bool
}

struct MPDSetRepeatAction: Action {
  let repeatState: Bool
}
