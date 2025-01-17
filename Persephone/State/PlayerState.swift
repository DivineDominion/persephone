//
//  PlayerState.swift
//  Persephone
//
//  Created by Daniel Barber on 2019/4/19.
//  Copyright © 2019 Dan Barber. All rights reserved.
//

import AppKit
import ReSwift

struct PlayerState: StateType {
  var status: MPDClient.MPDStatus?
  var currentSong: Song?
  var currentArtwork: NSImage?

  var state: MPDClient.MPDStatus.State?
  var shuffleState: Bool = false
  var repeatState: Bool = false

  var totalTime: UInt?
  var elapsedTimeMs: UInt?
}

extension PlayerState: Equatable {
  static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
    return (lhs.state == rhs.state) &&
      (lhs.totalTime == rhs.totalTime) &&
      (lhs.elapsedTimeMs == rhs.elapsedTimeMs) &&
      (lhs.shuffleState == rhs.shuffleState) &&
      (lhs.repeatState == rhs.repeatState)
  }
}
