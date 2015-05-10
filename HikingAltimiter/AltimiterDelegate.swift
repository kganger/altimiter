//
//  AltimiterDelegate.swift
//  AltimiterPlay
//
//  Created by Ganger, Keith E on 4/14/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation
protocol AltimiterDelegate{
    func didAltitudeChange(altimiter:Altimiter)
    
    func didStatusChange(status : String, isError: Bool)
        
    func didDestinationAltitudeChange(altimiter:Altimiter)
}