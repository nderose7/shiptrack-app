//
//  MainTabView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    init() {
        // Customizing tab bar appearance (optional)
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content of the TabView
            
            TabView {
                /*
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                 
                WebView(urlString: "https://cloudship-xi.vercel.app/dashboard")
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                
                WebView(urlString: "https://cloudship-xi.vercel.app/shipments")
                    .tabItem {
                        Label("Home", systemImage: "box")
                    }
                /*
                NewShipmentsView()
                    .tabItem {
                        Label("New", systemImage: "paperplane.fill")
                    }
                 */
                WebView(urlString: "https://cloudship-xi.vercel.app/products")
                    .tabItem {
                        Label("Locate", systemImage: "mappin.and.ellipse")
                    }

                
                MenuView()
                    .tabItem {
                        Label("Menu", systemImage: "person.crop.circle")
                    }*/
            }

            // Grey border at the top of the tab bar
            /*
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .offset(y: -59) // Adjust this value as needed
             */
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

