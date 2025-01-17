//
//  AppDelegate.swift
//  Persephone
//
//  Created by Daniel Barber on 2018/7/31.
//  Copyright © 2018 Dan Barber. All rights reserved.
//

import AppKit
import ReSwift
import MediaKeyTap

@NSApplicationMain
class AppDelegate: NSObject,
                   NSApplicationDelegate,
                   MediaKeyTapDelegate {
  var mediaKeyTap: MediaKeyTap?

  @IBOutlet weak var mainWindowMenuItem: NSMenuItem!
  @IBOutlet weak var updateDatabaseMenuItem: NSMenuItem!
  @IBOutlet weak var playSelectedSongMenuItem: NSMenuItem!
  @IBOutlet weak var playSelectedSongNextMenuItem: NSMenuItem!
  @IBOutlet weak var addSelectedSongToQueueMenuItem: NSMenuItem!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    App.mpdServerController.connect()
    instantiateUserNotificationsController()

    mediaKeyTap = MediaKeyTap(delegate: self)
    mediaKeyTap?.start()

    App.store.subscribe(self) {
      $0.select {
        $0.uiState
      }
    }
  }

  func instantiateUserNotificationsController() {
    _ = App.userNotificationsController
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    App.mpdServerController.disconnect()
  }

  func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    let dockMenu = NSMenu()
    dockMenu.autoenablesItems = false

    guard let state = App.store.state.playerState.state else { return nil }

    if let currentSong = App.store.state.playerState.currentSong,
      state.isOneOf([.playing, .paused]) {

      let nowPlayingItem = NSMenuItem(title: "Now Playing", action: nil, keyEquivalent: "")
      let songItem = NSMenuItem(title: currentSong.title, action: nil, keyEquivalent: "")
      let albumItem = NSMenuItem(
        title: "\(currentSong.artist) — \(currentSong.album.title)",
        action: nil,
        keyEquivalent: ""
      )

      nowPlayingItem.isEnabled = false
      songItem.indentationLevel = 1
      songItem.isEnabled = false
      albumItem.indentationLevel = 1
      albumItem.isEnabled = false

      dockMenu.addItem(nowPlayingItem)
      dockMenu.addItem(songItem)
      dockMenu.addItem(albumItem)
      dockMenu.addItem(NSMenuItem.separator())
    }

    let playPauseMenuItem = NSMenuItem(
      title: state == .playing ? "Pause" : "Play",
      action: #selector(playPauseMenuAction),
      keyEquivalent: ""
    )
    let stopMenuItem = NSMenuItem(title: "Stop", action: #selector(stopMenuAction), keyEquivalent: "")
    let nextTrackMenuItem = NSMenuItem(title: "Next", action: #selector(nextTrackMenuAction), keyEquivalent: "")
    let prevTrackMenuItem = NSMenuItem(title: "Previous", action: #selector(prevTrackMenuAction), keyEquivalent: "")

    playPauseMenuItem.isEnabled = state.isOneOf([.playing, .paused, .stopped])
    stopMenuItem.isEnabled = state.isOneOf([.playing, .paused])
    nextTrackMenuItem.isEnabled = state.isOneOf([.playing, .paused])
    prevTrackMenuItem.isEnabled = state.isOneOf([.playing, .paused])

    dockMenu.addItem(playPauseMenuItem)
    dockMenu.addItem(stopMenuItem)
    dockMenu.addItem(nextTrackMenuItem)
    dockMenu.addItem(prevTrackMenuItem)

    return dockMenu
  }

  func setMainWindowStateMenuItem(state: MainWindowState) {
    switch state {
    case .open: mainWindowMenuItem.state = .on
    case .closed: mainWindowMenuItem.state = .off
    case .minimised: mainWindowMenuItem.state = .mixed
    }
  }

  func setSongMenuItemsState(selectedSong: Song?) {
    playSelectedSongMenuItem.isEnabled = selectedSong != nil
    playSelectedSongNextMenuItem.isEnabled = selectedSong != nil
    addSelectedSongToQueueMenuItem.isEnabled = selectedSong != nil
  }

  func handle(mediaKey: MediaKey, event: KeyEvent) {
    switch mediaKey {
    case .playPause:
      App.store.dispatch(MPDPlayPauseAction())
    case .next, .fastForward:
      App.store.dispatch(MPDNextTrackAction())
    case .previous, .rewind:
      App.store.dispatch(MPDPrevTrackAction())
    }
  }

  @IBAction func updateDatabase(_ sender: NSMenuItem) {
    App.store.dispatch(MPDUpdateDatabaseAction())
  }

  @IBAction func playPauseMenuAction(_ sender: NSMenuItem) {
    App.store.dispatch(MPDPlayPauseAction())
  }
  @IBAction func stopMenuAction(_ sender: NSMenuItem) {
    App.store.dispatch(MPDStopAction())
  }
  @IBAction func nextTrackMenuAction(_ sender: NSMenuItem) {
    App.store.dispatch(MPDNextTrackAction())
  }
  @IBAction func prevTrackMenuAction(_ sender: NSMenuItem) {
    App.store.dispatch(MPDPrevTrackAction())
  }

  @IBAction func removeQueueSongMenuAction(_ sender: NSMenuItem) {
    guard let queueItem = App.store.state.uiState.selectedQueueItem
      else { return }

    App.store.dispatch(MPDRemoveTrack(queuePos: queueItem.queuePos))
    App.store.dispatch(SetSelectedQueueItem(selectedQueueItem: nil))
  }
  @IBAction func clearQueueMenuAction(_ sender: NSMenuItem) {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "Are you sure you want to clear the queue?"
    alert.informativeText = "You can’t undo this action."
    alert.addButton(withTitle: "Clear Queue")
    alert.addButton(withTitle: "Cancel")

    let result = alert.runModal()

    if result == .alertFirstButtonReturn {
      App.store.dispatch(MPDClearQueue())
    }
  }

  @IBAction func playSelectedSongAction(_ sender: NSMenuItem) {
    guard let song = App.store.state.uiState.selectedSong
      else { return }

    let queueLength = App.store.state.queueState.queue.count
    App.store.dispatch(MPDAppendTrack(song: song.mpdSong))
    App.store.dispatch(MPDPlayTrack(queuePos: queueLength))
  }
  @IBAction func playSelectedSongNextAction(_ sender: NSMenuItem) {
    let queuePos = App.store.state.queueState.queuePos

    guard let song = App.store.state.uiState.selectedSong,
      queuePos > -1
      else { return }

    App.store.dispatch(
      MPDAddSongToQueue(songUri: song.mpdSong.uriString, queuePos: queuePos + 1)
    )
  }
  @IBAction func addSelectedSongToQueueAction(_ sender: NSMenuItem) {
    guard let song = App.store.state.uiState.selectedSong
      else { return }

    App.store.dispatch(MPDAppendTrack(song: song.mpdSong))
  }
}

extension AppDelegate: StoreSubscriber {
  typealias StoreSubscriberStateType = UIState

  func newState(state: UIState) {
    updateDatabaseMenuItem.isEnabled = !state.databaseUpdating
    setMainWindowStateMenuItem(state: state.mainWindowState)
    setSongMenuItemsState(selectedSong: state.selectedSong)
  }
}
