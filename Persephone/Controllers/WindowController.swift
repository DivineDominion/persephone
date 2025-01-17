//
//  WindowController.swift
//  Persephone
//
//  Created by Daniel Barber on 2019/1/11.
//  Copyright © 2019 Dan Barber. All rights reserved.
//

import AppKit
import ReSwift

class WindowController: NSWindowController {
  enum TransportAction: Int {
    case prevTrack, playPause, stop, nextTrack
  }

  var state: MPDClient.MPDStatus.State?
  var trackTimer: Timer?

  @IBOutlet var transportControls: NSSegmentedCell!

  @IBOutlet var trackProgress: NSTextField!
  @IBOutlet var trackProgressBar: NSSlider!
  @IBOutlet var trackRemaining: NSTextField!
  @IBOutlet var databaseUpdatingIndicator: NSProgressIndicator!

  @IBOutlet var shuffleState: NSButton!
  @IBOutlet var repeatState: NSButton!

  override func windowDidLoad() {
    super.windowDidLoad()
    window?.titleVisibility = .hidden
    window?.isExcludedFromWindowsMenu = true

    App.store.subscribe(self) {
      $0.select {
        ($0.playerState, $0.uiState)
      }
    }

    App.store.dispatch(MainWindowDidOpenAction())

    trackProgress.font = .timerFont
    trackRemaining.font = .timerFont
  }

  override func keyDown(with event: NSEvent) {
    switch event.keyCode {
    case NSEvent.keyCodeSpace:
      App.store.dispatch(MPDPlayPauseAction())
    default:
      nextResponder?.keyDown(with: event)
    }
  }

  func setTransportControlState(_ state: PlayerState) {
    guard let state = state.state else { return }

    transportControls.setEnabled(state.isOneOf([.playing, .paused]), forSegment: 0)
    transportControls.setEnabled(state.isOneOf([.playing, .paused, .stopped]), forSegment: 1)
    transportControls.setEnabled(state.isOneOf([.playing, .paused]), forSegment: 2)
    transportControls.setEnabled(state.isOneOf([.playing, .paused]), forSegment: 3)

    if state.isOneOf([.paused, .stopped, .unknown]) {
      transportControls.setImage(.playIcon, forSegment: 1)
    } else {
      transportControls.setImage(.pauseIcon, forSegment: 1)
    }
  }

  func setShuffleRepeatState(_ state: PlayerState) {
    shuffleState.state = state.shuffleState ? .on : .off
    repeatState.state = state.repeatState ? .on : .off
  }

  func setTrackProgressControls(_ playerState: PlayerState) {
    guard let state = playerState.state,
      let totalTime = playerState.totalTime,
      let elapsedTimeMs = playerState.elapsedTimeMs
      else { return }

    trackProgressBar.isEnabled = state.isOneOf([.playing, .paused])
    trackProgressBar.maxValue = Double(totalTime * 1000)
    trackProgressBar.integerValue = Int(elapsedTimeMs)

    setTimeElapsed(elapsedTimeMs)
    setTimeRemaining(elapsedTimeMs, totalTime * 1000)
  }

  func setDatabaseUpdatingIndicator(_ uiState: UIState) {
    if uiState.databaseUpdating {
      databaseUpdatingIndicator.startAnimation(self)
    } else {
      databaseUpdatingIndicator.stopAnimation(self)
    }
  }

  func setTimeElapsed(_ elapsedTimeMs: UInt?) {
    guard let elapsedTimeMs = elapsedTimeMs else { return }

    let time = Time(timeInSeconds: Int(elapsedTimeMs) / 1000)

    trackProgress.stringValue = time.formattedTime
  }

  func setTimeRemaining(_ elapsedTimeMs: UInt?, _ totalTime: UInt?) {
    guard let elapsedTimeMs = elapsedTimeMs,
      let totalTime = totalTime
      else { return }

    let time = Time(
      timeInSeconds: -(Int(totalTime) - Int(elapsedTimeMs)) / 1000
    )

    trackRemaining.stringValue = time.formattedTime
  }

  // TODO: Refactor this using a gesture recognizer
  @IBAction func changeTrackProgress(_ sender: NSSlider) {
    guard let event = NSApplication.shared.currentEvent
      else { return }

    switch event.type {
    case .leftMouseDown:
      trackTimer?.invalidate()
    case .leftMouseDragged:
      App.store.dispatch(
        UpdateElapsedTimeAction(elapsedTimeMs: UInt(sender.integerValue))
      )
    case .leftMouseUp:
      let seekTime = Float(sender.integerValue) / 1000

      App.store.dispatch(MPDSeekCurrentSong(timeInSeconds: seekTime))
    default:
      break
    }
  }

  @IBAction func handleTransportControl(_ sender: NSSegmentedControl) {
    guard let transportAction = TransportAction(rawValue: sender.selectedSegment)
      else { return }

    switch transportAction {
    case .prevTrack:
      App.store.dispatch(MPDPrevTrackAction())
    case .playPause:
      App.store.dispatch(MPDPlayPauseAction())
    case .stop:
      App.store.dispatch(MPDStopAction())
    case .nextTrack:
      App.store.dispatch(MPDNextTrackAction())
    }
  }

  @IBAction func handleShuffleButton(_ sender: NSButton) {
    App.store.dispatch(MPDSetShuffleAction(shuffleState: sender.state == .on))
  }

  @IBAction func handleRepeatButton(_ sender: NSButton) {
    App.store.dispatch(MPDSetRepeatAction(repeatState: sender.state == .on))
  }

}

extension WindowController: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    App.store.dispatch(MainWindowDidCloseAction())
  }

  func windowWillMiniaturize(_ notification: Notification) {
    App.store.dispatch(MainWindowDidMinimizeAction())
  }

  func windowDidDeminiaturize(_ notification: Notification) {
    App.store.dispatch(MainWindowDidOpenAction())
  }
}

extension WindowController: StoreSubscriber {
  typealias StoreSubscriberStateType = (playerState: PlayerState, uiState: UIState)

  func newState(state: (playerState: PlayerState, uiState: UIState)) {
    DispatchQueue.main.async {
      self.setTransportControlState(state.playerState)
      self.setShuffleRepeatState(state.playerState)
      self.setTrackProgressControls(state.playerState)
      self.setDatabaseUpdatingIndicator(state.uiState)
    }
  }
}
