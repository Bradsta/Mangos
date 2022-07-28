//
//  SceneDelegate.swift
//  Mangos
//
//  Created by Brad Guerrero on 11/7/19.
//  Copyright © 2019 Brad Guerrero. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            _ = Utility.handleIncomingURL(url)
        }
    }
    
}
