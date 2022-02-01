//
//  ViewController.swift
//  LARScan
//
//  Created by Jean Flaherty on 2022/01/23.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import LocalizeAR
import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, CLLocationManagerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var modeControl: UISegmentedControl!
    @IBOutlet var actionButton: UIButton!
    
    var mapper: LARLiveMapper!
    var tracker: LARTracker!
    
    let locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        return locationManager
    }()
    
    let mapAnchor = ARAnchor(name: "mapAnchor", transform: matrix_identity_float4x4)
    let mapNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapper = LARLiveMapper(directory: createSessionDirctory()!)
        Task {
            await LARTracker(map: mapper.data.map)
        }
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        locationManager.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ .showWorldOrigin, .showFeaturePoints ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .smoothedSceneDepth
        configuration.worldAlignment = .gravity

        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.add(anchor: mapAnchor)
        
        // This constraint allows landmarks to be visible from far away
        guard let pointOfView = sceneView.pointOfView else { return }
        scaleConstraint = SCNScreenSpaceScaleConstraint(pointOfView: pointOfView)
        landmarkNode.constraints = [scaleConstraint]
        unusedLandmarkNode.constraints = [scaleConstraint]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        sceneView.session.remove(anchor: mapAnchor)
    }
    
    func createSessionDirctory() -> URL? {
        let sessionName = Int(round(Date().timeIntervalSince1970 * 1e3)).description
        guard let sessionDirectory = try? FileManager.default
            .url(for: .documentDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent(sessionName, isDirectory: true)
        else { return nil }
        try? FileManager.default.createDirectory(at: sessionDirectory, withIntermediateDirectories: true, attributes: nil)
        return sessionDirectory
    }
    
    // MARK: - IBAction
    
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        let actionTitle = ["Snap", "Localize"][sender.selectedSegmentIndex]
        actionButton.setTitle(actionTitle, for: .normal)
        
        switch sender.selectedSegmentIndex {
            case 0: break
            case 1: Task { tracker = await LARTracker(map: mapper.data.map) }
            default: break
        }
    }
    
    @IBAction func actionButtonPressed(_ button: UIButton) {
        switch modeControl.selectedSegmentIndex {
            case 0: snap()
            case 1: localize()
            default: break
        }
    }
    
    func snap() {
        guard let frame = sceneView.session.currentFrame else { return }
        
        AudioServicesPlaySystemSound(SystemSoundID(1108))
        Task.detached(priority: .low) { [self] in
            await mapper.add(frame: frame)
            await mapper.writeMetadata()
            await mapper.process()
            await renderDebug()
        }
    }
    
    func localize() {
        guard let frame = sceneView.session.currentFrame else { return }
        Task.detached(priority: .userInitiated) { [self] in
            if let transform = await tracker.localize(frame: frame) {
                print("t:", transform)
            }
        }
    }

    // MARK: - ARSCNViewDelegate
    
    var scaleConstraint: SCNTransformConstraint!
    
    let locationNode = SCNNode.sphere(radius: 0.005, color: UIColor.systemBlue)
    let unusedLandmarkNode = SCNNode.sphere(radius: 0.002, color: UIColor.gray)
    let landmarkNode = SCNNode.sphere(radius: 0.002, color: UIColor.green)

//     Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        return anchor == mapAnchor ? mapNode : nil
    }
    
    var landmarkNodes: [SCNNode] = []
    var locationNodes: [SCNNode] = []
    
    func renderDebug() async {
        landmarkNodes.forEach { $0.removeFromParentNode() }
        landmarkNodes.removeAll()
        
        let (landmarks, gpsObservations) = await (mapper.data.map.landmarks, mapper.data.gpsObservations)
        
        // Populate landmark nodes
        for landmark in prioritizedLandmarks(landmarks, max: 1000) {
            let node = landmark.isUsable() ? landmarkNode.clone() : unusedLandmarkNode.clone()
            node.transform = transformFrom(position: landmark.position)
            mapNode.addChildNode(node)
            landmarkNodes.append(node)
        }
        
        // Populate location nodes
        for observation in gpsObservations.suffix(gpsObservations.count - locationNodes.count) {
            let node = locationNode.clone()
            node.transform = transformFrom(position: observation.relative)
            mapNode.addChildNode(node)
            locationNodes.append(node)
        }
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    // MARK: ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let timestamp = dateFrom(uptime: frame.timestamp)
        let position = simd_make_float3(frame.camera.transform.columns.3)
        Task.detached(priority: .low) { [mapper] in
            await mapper?.add(position: position, timestamp: timestamp)
        }
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task.detached(priority: .low) { [mapper] in
            await mapper?.add(locations: locations)
        }
    }
}
