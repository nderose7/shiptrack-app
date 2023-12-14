//
//  PageContainer.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import Foundation
import SwiftUI

struct PageContainer<Content: View>: View {
    var alignment: HorizontalAlignment
    let title: String
    var subtitle: String?
    let content: Content
    
    init(alignment: HorizontalAlignment = .leading, title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment) {
            Text(title)
                .font(.custom("Avenir", size: 24))
                .fontWeight(.bold)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
            
            
            Spacer().frame(height: 5)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .multilineTextAlignment(alignment == .center ? .center : .leading)
            }
                
            content
                .frame(maxWidth: .infinity)
                .font(.custom("Avenir", size: 16))
                

            Spacer() // Pushes the content to the top
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline) // Optional, for inline navigation bar title
    }
}
