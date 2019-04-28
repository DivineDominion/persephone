//
//  CurrentArtView.swift
//  Persephone
//
//  Created by Daniel Barber on 2019/4/27.
//  Copyright © 2019 Dan Barber. All rights reserved.
//

import Cocoa
import ReSwift

class CurrentArtView: NSImageView {
  required init?(coder: NSCoder) {
    super.init(coder: coder)

    AppDelegate.store.subscribe(self) {
      $0.select { $0.playerState.currentArtwork }
    }
  }
}

extension CurrentArtView: StoreSubscriber {
  typealias StoreSubscriberStateType = NSImage?

  func newState(state: NSImage?) {
    if let coverArt = state {
      image = coverArt
    } else {
      image = .defaultCoverArt
    }
  }
}
