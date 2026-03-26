//
//  DeviceProviding.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

protocol DeviceProviding {
    func loadDevices() -> [Device]
}