//
//  Transport.swift
//  Persephone
//
//  Created by Daniel Barber on 2019/3/15.
//  Copyright © 2019 Dan Barber. All rights reserved.
//

import Foundation
import mpdclient

extension MPDClient {
  func playPause() {
    enqueueCommand(command: .playPause)
  }

  func stop() {
    enqueueCommand(command: .stop)
  }

  func prevTrack() {
    enqueueCommand(command: .prevTrack)
  }

  func nextTrack() {
    enqueueCommand(command: .nextTrack)
  }

  func seekCurrentSong(timeInSeconds: Float) {
    enqueueCommand(
      command: .seekCurrentSong,
      userData: ["timeInSeconds": timeInSeconds]
    )
  }

  func setShuffleState(shuffleState: Bool) {
    enqueueCommand(
      command: .setShuffleState,
      userData: ["shuffleState": shuffleState]
    )
  }

  func setRepeatState(repeatState: Bool) {
    enqueueCommand(
      command: .setRepeatState,
      userData: ["repeatState": repeatState]
    )
  }

  func sendNextTrack() {
    guard let state = status?.state,
      state.isOneOf([.playing, .paused])
      else { return }

    mpd_run_next(connection)
  }

  func sendPreviousTrack() {
    guard let state = status?.state,
      state.isOneOf([.playing, .paused])
      else { return }

    mpd_run_previous(connection)
  }

  func sendStop() {
    mpd_run_stop(connection)
  }

  func sendPlay() {
    if status?.state == .stopped {
      mpd_run_play(connection)
    } else {
      mpd_run_toggle_pause(connection)
    }
  }

  func sendSeekCurrentSong(timeInSeconds: Float) {
    mpd_run_seek_current(self.connection, timeInSeconds, false)
  }

  func sendShuffleState(shuffleState: Bool) {
    mpd_run_random(self.connection, shuffleState)
  }

  func sendRepeatState(repeatState: Bool) {
    mpd_run_repeat(self.connection, repeatState)
  }
}
