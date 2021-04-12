//
//  Extensions.swift
//  eyeCarousel
//
//  Created by Stone Chen on 4/2/21.
//

import Foundation

extension String {
    func isAlphanumeric() -> Bool {
        return !self.isEmpty && self.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}
