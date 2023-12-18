//
//  LabelDisplayView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/14/23.
//

import Foundation
import SwiftUI

struct LabelDisplayView: View {
    var labelInfo: LabelInfo?

    var body: some View {
        VStack {
            if let labelInfo = labelInfo, let url = URL(string: labelInfo.label_url) {
                // Display label as an image
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
            } else {
                Text("No label information available.")
            }
        }
    }
}
