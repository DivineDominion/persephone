//
//  AlbumViewItem.swift
//  Persephone
//
//  Created by Daniel Barber on 2019/2/08.
//  Copyright © 2019 Dan Barber. All rights reserved.
//

import AppKit

class AlbumViewItem: NSCollectionViewItem {
  var observer: NSKeyValueObservation?
  var album: Album?

  override func viewDidLoad() {
    super.viewDidLoad()

    albumCoverView.wantsLayer = true
    albumCoverView.layer?.cornerRadius = 3
    albumCoverView.layer?.borderWidth = 1
    setAppearance()

    if #available(OSX 10.14, *) {
      observer = NSApp.observe(\.effectiveAppearance) { (app, _) in
        self.setAppearance()
      }
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    AlbumDetailView.popover.close()
  }

  func setAlbum(_ album: Album) {
    self.album = album
    albumTitle.stringValue = album.title
    albumArtist.stringValue = album.artist

    switch album.coverArt {
    case .loaded(let coverArt):
      albumCoverView.image = coverArt ?? .defaultCoverArt
    default:
      albumCoverView.image = .defaultCoverArt
    }
  }

  func setAppearance() {
    if #available(OSX 10.14, *) {
      let darkMode = NSApp.effectiveAppearance.bestMatch(from:
        [.darkAqua, .aqua]) == .darkAqua

      albumCoverView.layer?.borderColor = darkMode ? .albumBorderColorDark : .albumBorderColorLight
    } else {
      albumCoverView.layer?.borderColor = .albumBorderColorLight
    }
  }

  @IBAction func showAlbumDetail(_ sender: NSButton) {
    guard let album = album else { return }

    AlbumDetailView.shared.setAlbum(album)

    AlbumDetailView.popover.contentViewController = AlbumDetailView.shared
    AlbumDetailView.popover.behavior = .transient
    AlbumDetailView.popover.show(
      relativeTo: sender.bounds,
      of: sender,
      preferredEdge: .maxY
    )
  }

  @IBOutlet var albumCoverView: NSButton!
  @IBOutlet var albumTitle: NSTextField!
  @IBOutlet var albumArtist: NSTextField!
}
