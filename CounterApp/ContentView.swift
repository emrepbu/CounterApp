//
//  ContentView.swift
//  CounterApp
//
//  Created by emre argana on 8.06.2025.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    // MARK: - State Properties
    @State private var number: Int = 0
    @State private var isCountingDown: Bool = true
    @State private var timer: Timer?
    @State private var currentSpeed: Double = 0.0
    @State private var isActive: Bool = false
    
    // MARK: - Debug Properties
    @State private var showDebug: Bool = false
    @State private var deviceOrientation: String = "Unknown"
    @State private var yValue: Double = 0.0
    
    // MARK: - Motion Manager
    private let motionManager = CMMotionManager()
    
    var body: some View {
        VStack {
            
            Spacer()
            
            // MARK: - Number Display Section
            VStack(spacing: 0) {
                // Next number (n+1)
                Text("\(number + 1)")
                    .font(.system(size: 45, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .scaleEffect(0.7)
                    .opacity(0.3)
                    .contentTransition(.numericText(countsDown: isCountingDown))
                
                // Current number (n)
                Text("\(number)")
                    .font(.system(size: 50, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText(countsDown: isCountingDown))
                    .padding(.vertical, -10)
                
                // Previous number (n-1)
                Text("\(number - 1)")
                    .font(.system(size: 45, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .scaleEffect(0.7)
                    .opacity(0.3)
                    .contentTransition(.numericText(countsDown: isCountingDown))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: number)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.2),
                        .init(color: .black, location: 0.8),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            
            // MARK: - Control Buttons
            HStack {
                Spacer()
                
                Button {
                    isCountingDown = false
                    withAnimation {
                        number -= 1
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button {
                    isCountingDown = true
                    withAnimation {
                        number += 1
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            
            Spacer()
            
            // MARK: - Debug Toggle
            Button("Debug Info") {
                showDebug.toggle()
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            startMotionUpdates()
            startTimer()
        }
        .onDisappear {
            motionManager.stopAccelerometerUpdates()
            timer?.invalidate()
        }
        .sheet(isPresented: $showDebug) {
            VStack {
                Text("Debug Console")
                    .font(.title2)
                    .bold()
                    .padding()
                
                List {
                    HStack {
                        Text("Orientation")
                        Spacer()
                        Text(deviceOrientation)
                    }
                    
                    HStack {
                        Text("Speed")
                        Spacer()
                        Text("\(String(format: "%.2fx", currentSpeed))")
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isActive ? "Active" : "Inactive")
                    }
                    
                    HStack {
                        Text("Y Value")
                        Spacer()
                        Text("\(String(format: "%.3f", yValue))")
                    }
                    
                    HStack {
                        Text("Count Direction")
                        Spacer()
                        Text(isCountingDown ? "Up ↑" : "Down ↓")
                    }
                }
                
                Link(destination: URL(string: "https://github.com/emrepbu/CounterApp")!) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .font(.title3)
                        Text("github.com/emrepbu/CounterApp")
                            .font(.footnote)
                    }
                    .foregroundColor(Color.blue)
                }
                .padding(.top, 5)
                
                Button("Done") {
                    showDebug = false
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        var counter: Double = 0.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isActive && currentSpeed > 0 {
                counter += currentSpeed * 0.1
                
                if counter >= 0.5 {
                    withAnimation {
                        if isCountingDown {
                            number += 1
                        } else {
                            number -= 1
                        }
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    counter = 0.0
                }
            } else {
                counter = 0.0
            }
        }
    }
    
    // MARK: - Motion Detection
    private func startMotionUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1
        
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            guard let data = data else { return }
            
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            
            yValue = y
            
            var newOrientation = ""
            
            if abs(z) > 0.8 {
                newOrientation = z > 0 ? "Face Down" : "Face Up"
                isActive = false
                currentSpeed = 0
                
            } else if abs(x) > 0.5 {
                newOrientation = x > 0 ? "Landscape Right" : "Landscape Left"
                isActive = false
                currentSpeed = 0
                
            } else if y < -0.3 {
                newOrientation = "Portrait"
                isActive = true
                isCountingDown = true
                
                let normalizedY = max(0, min(1, (abs(y) - 0.3) / 0.7))
                currentSpeed = 0.5 + (normalizedY * 2.5)
                
            } else if y > 0.3 {
                newOrientation = "Portrait Upside Down"
                isActive = true
                isCountingDown = false
                
                let normalizedY = max(0, min(1, (abs(y) - 0.3) / 0.7))
                currentSpeed = 0.5 + (normalizedY * 2.5)
                
            } else {
                newOrientation = "Flat"
                isActive = false
                currentSpeed = 0
            }
            
            deviceOrientation = newOrientation
        }
    }
}

#Preview {
    ContentView()
}
