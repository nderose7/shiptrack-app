//
//  NewView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import Foundation
import SwiftUI
import AVFoundation
import Vision

typealias SerialNumberScanHandler = (String, UIImage) -> Void

struct CameraView: UIViewControllerRepresentable {
    @Binding var cameraViewController: CameraViewController?

    var onSerialNumberScanned: SerialNumberScanHandler

    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.onSerialNumberScanned = onSerialNumberScanned
        self.cameraViewController = viewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update the view controller if needed.
    }
}


class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue?
    var onSerialNumberScanned: SerialNumberScanHandler = { _, _ in }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if targetEnvironment(simulator)
        performTextRecognitionWithTestImage()
        #else
        setupCamera()
        #endif
    }
    
    
    func stopCamera() {
        captureSession?.stopRunning()
    }
    
    
    func performTextRecognitionWithTestImage() {
        guard let testImage = UIImage(named: "testSerial"), let cgImage = testImage.cgImage else {
            print("Failed to load test image")
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else { return }
            let serialNumbers = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            if let serialNumber = serialNumbers.first {
                DispatchQueue.main.async {
                    self?.onSerialNumberScanned(serialNumber, testImage)
                }
            }

        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        
        if let videoDevice = AVCaptureDevice.default(for: .video) {
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                if captureSession.canAddInput(videoDeviceInput) {
                    captureSession.addInput(videoDeviceInput)
                }
            } catch {
                print("Error: Unable to initialize video device input: \(error)")
                return
            }
        } else {
            print("Error: No video devices available")
            return
        }
        
        videoDataOutput = AVCaptureVideoDataOutput()
        guard let videoDataOutput = videoDataOutput else { return }
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            
            // Set the orientation of the video output to portrait
            if let connection = videoDataOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else { return }
            let serialNumbers = observations.compactMap { observation in
                // Extract the top candidate from each observation
                observation.topCandidates(1).first?.string
            }
            
            if let serialNumber = serialNumbers.first, let image = self?.convertToUIImage(sampleBuffer: sampleBuffer) {
                DispatchQueue.main.async {
                    self?.onSerialNumberScanned(serialNumber, image)
                }
            }

        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([textRequest])
    }
    
    func convertToUIImage(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

}

extension ProductService {
    func fetchProduct(bySerialNumber serialNumber: String, completion: @escaping (ProductData?) -> Void) {
        fetchProducts { productsData, error in
            guard let productsData = productsData, error == nil else {
                completion(nil)
                return
            }

            // Find the product with the matching serial number directly in ProductData
            let foundProduct = productsData.first { data in
                data.serial == serialNumber
            }

            DispatchQueue.main.async {
                completion(foundProduct)
            }
        }
    }
}



enum NavigationTarget: Hashable {
    case shipView(String)
}

struct Product: Decodable {
    var name: String
    var description: String
    var serial: String
    var length: Int
    var width: Int
    var height: Int
    var weight: Int
}




struct NewShipmentsView: View, Hashable {
    @State private var scannedSerialNumber: String = ""
    @State private var scannedImage: UIImage?
    @State private var navigateToShipView = false
    @State private var foundProduct: ProductData?
    @State private var isFetchingProduct = false
    @StateObject private var shippingData = ShippingData()
    @State private var cameraViewController: CameraViewController?
    @Binding var showScanner: Bool
    @EnvironmentObject var webViewManager: WebViewManager
    
    func hash(into hasher: inout Hasher) {
        // You can use a constant or a unique property to hash
        hasher.combine("NewShipmentsView")
    }
    
    func passDataToWebView() {
        if let productId = foundProduct?.id {
            print("Product id found...", productId)
            let script = "receiveDataFromNative(\(productId))"
            webViewManager.coordinator?.evaluateJavaScript(script)
        } else {
            print("Product data is not available")
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageContainer(alignment: .center, title: "Scan Serial Number", subtitle: "", content:  {
                    CameraView(cameraViewController: $cameraViewController) { serialNumber, image in
                        self.scannedSerialNumber = serialNumber
                        self.scannedImage = image
                        self.isFetchingProduct = true
                        ProductService().fetchProduct(bySerialNumber: serialNumber) { productData in
                            self.foundProduct = productData
                            self.isFetchingProduct = false
                            if productData != nil {
                                self.cameraViewController?.stopCamera() // Stop the camera here
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) 
                    
                    if let image = scannedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                    }
                    
                    if !scannedSerialNumber.isEmpty {
                        VStack {
                            Text("Scanned Serial Number:")
                                .multilineTextAlignment(.center)
                                .font(.custom("Avenir", size: 18))
                                .fontWeight(.bold)
                            
                            Spacer().frame(height: 8)
                            
                            Text(scannedSerialNumber)
                                .multilineTextAlignment(.center)
                                .font(.custom("Avenir", size: 20))
                            
                            Spacer().frame(height: 20)
                            
                            if isFetchingProduct {
                                Text("Searching for product...")
                            } else if let productData = foundProduct {
                                // Display product details
                                Text("Product Found:")
                                    .multilineTextAlignment(.center)
                                    .font(.custom("Avenir", size: 18))
                                    .fontWeight(.bold)
                                
                                Spacer().frame(height: 8)
                                
                                Text(productData.name)
                                    .multilineTextAlignment(.center)
                                    .font(.custom("Avenir", size: 18))
                                
                                
                                Button("Done") {
                                    // Close sheet and pass data to web view
                                    print("Trying to close...")
                                    passDataToWebView()
                                    self.showScanner = false
                                }
                                .padding(.leading, 40)
                                .padding(.trailing, 40)
                                .padding(.bottom, 20)
                                .padding(.top, 20)
                                .background(Color.hex("0177CC"))
                                .foregroundColor(.white)
                                .font(.custom("Avenir", size: 20))
                                .fontWeight(.bold)
                                .cornerRadius(100) // Change this value for different corner radius sizes
                                .padding()
                                
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .navigationDestination(isPresented: $navigateToShipView) {
                            if let productData = foundProduct {
                                ShipView(product: productData, shippingData: shippingData)
                            } else {
                                Text("No product found for the serial number")
                            }
                            
                        }
                    }
                    Spacer() // Pushes the content to the top
                })
            }
            .padding(0)
        }
    }
    // Implement the == operator for Hashable conformance
    static func ==(lhs: NewShipmentsView, rhs: NewShipmentsView) -> Bool {
        // You can compare based on a unique property
        return true // For this simple case, all instances are considered equal
    }
}




