import ARKit

func createNode(_ geometry: SCNGeometry?, fromDict dict: Dictionary<String, Any>, forDevice device: MTLDevice?) async -> SCNNode? {
    let dartType = dict["dartType"] as! String
    
    let node: SCNNode? = await dartType == "ARKitReferenceNode"
        ? createReferenceNode(dict)
        : SCNNode(geometry: geometry);
  
    if(node != nil) {
        updateNode(node!, fromDict: dict, forDevice: device);
    }
    
    return node;
}

func updateNode(_ node: SCNNode, fromDict dict: Dictionary<String, Any>, forDevice device: MTLDevice?) {
    if let transform = dict["transform"] as? Array<NSNumber> {
        node.transform = deserializeMatrix4(transform)
    }
    
    if let name = dict["name"] as? String {
        node.name = name
    }
    
    if let physicsBody = dict["physicsBody"] as? Dictionary<String, Any> {
        node.physicsBody = createPhysicsBody(physicsBody, forDevice: device)
    }
    
    if let light = dict["light"] as? Dictionary<String, Any> {
        node.light = createLight(light)
    }
    
    if let renderingOrder = dict["renderingOrder"] as? Int {
        node.renderingOrder = renderingOrder
    }
    
    if let isHidden = dict["isHidden"] as? Bool {
        node.isHidden = isHidden
    }
}

fileprivate func createReferenceNode(_ dict: Dictionary<String, Any>) async -> SCNNode? {
    let remoteUrl: String? = dict["remoteUrl"] as! String?;
    let url: String? = dict["url"] as! String?;
    
    print("remoteUrl:", remoteUrl as Any);
    print("url:", url as Any);
    
    var node: SCNNode?;
    var referenceUrl: URL;
    
    if(remoteUrl != nil && !remoteUrl!.isEmpty) {
        node = await getUSDZNodeFromURL(urlString: remoteUrl!);
    }
    else if let bundleURL = Bundle.main.url(forResource: url, withExtension: nil){
        referenceUrl = bundleURL;
        let refNode:SCNReferenceNode? = await SCNReferenceNode(url: referenceUrl);
        await refNode?.load();
        node = refNode;
    }
    else if(url != nil && !url!.isEmpty) {
        referenceUrl = URL(fileURLWithPath: url!);
        let refNode:SCNReferenceNode? = await SCNReferenceNode(url: referenceUrl);
        await refNode?.load();
        node = refNode;
    }
    return node;
}

func getUSDZNodeFromURL(urlString: String) async -> SCNNode? {
    print("ViewController().getUSDZNodeFromURL() called for url:", urlString);
        
    let downloadedUrl: URL?;
    do {
        print("Getting Downloaded Url");
        downloadedUrl = try await HttpDownloader().downloadFileAsync(fileURLString: urlString, filePathString: nil);
        print("Got Downloaded Url:", downloadedUrl as Any);
    }
    catch {
        print("Error in Getting Downloaded Url in ViewController().getUSDZNodeFromURL():", error);
        return nil;
    }
    
//        let fileName = "Croton_not_a_Snake_Plant.usdz";
    let fileName = "M1887_Free_Fire.usdz";
//        let fileName = "ufo.usdz";
    
    let filePathUrl = copyFile(sourceFileUrl: downloadedUrl!, filePath: nil, fileName: fileName);
    
    if(filePathUrl == nil) {
        print("Returning from ViewController().getUSDZNodeFromURL() because filePathUrl is nil");
        return nil;
    }
    
    let finalFileUrl: URL = filePathUrl!;
    
    //2. Load The Scene Remembering The Init Takes ONLY A Local URL
    let modelScene: SCNScene?;
    do {
        print("Getting modelScene");
        modelScene = try SCNScene(url: finalFileUrl, options: nil);
        print("Got modelScene:", downloadedUrl as Any);
    }
    catch {
        print("Error in Getting modelScene in ViewController().getUSDZNodeFromURL():", error);
        return nil;
    }
    
    if(modelScene == nil) {
        print("Returning from ViewController().getUSDZNodeFromURL() because modelScene couldn't got");
        return nil;
    }
    
    //3. Create A Node To Hold All The Content
    let modelHolderNode: SCNNode = await SCNNode();
    
    //4. Get All The Nodes From The SCNFile
    let nodeArray = await modelScene!.rootNode.childNodes;
    
    //5. Add Them To The Holder Node
    for childNode in nodeArray {
        await modelHolderNode.addChildNode(childNode as SCNNode);
    }
    
    await modelHolderNode.setPosition(position: SCNVector3(x: 0, y: -10, z: -25));
    
    return modelHolderNode;
}

extension SCNNode {
    public func setPosition(position: SCNVector3) {
        self.position = position;
    }
}

func copyFile(sourceFileUrl: URL, filePath: String?, fileName: String?) -> URL? {
    var finalFilePathString: String? = filePath;
    
    if(finalFilePathString == nil && fileName != nil) {
        let documentsDirectory: URL? = getDocumentsDirectory();
        print("documentsDirectory:", documentsDirectory as Any);
        
        if(documentsDirectory != nil) {
            finalFilePathString = documentsDirectory!.appendingPathComponent(fileName!).path;
        }
    }
    
    if(finalFilePathString == nil) {
        return nil;
    }
    
    let sourceFilePathUrl: URL = sourceFileUrl;
    let finalFilePathUrl: URL = URL(fileURLWithPath: finalFilePathString!, isDirectory: false);
    
    print("sourceFilePathUrl:", sourceFilePathUrl);
    print("finalFilePathUrl:", finalFilePathUrl);
    
    do {
        try FileManager.default.copyItem(at: sourceFilePathUrl, to: finalFilePathUrl);
        
        print("Successfuly Saved File \(finalFilePathUrl)")
        
        return finalFilePathUrl;
    } catch {
        print("Error Saving: \(error)");
        
        return finalFilePathUrl;
    }
}

func getDocumentsDirectory() -> URL? {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask);
    print("paths.count:", paths.count);
    
    if(paths.count == 0) {
        print("returning from getDocumentsDirectory because paths count is zero");
        return nil;
    }
    
    let documentsDirectory = paths[0];
    return documentsDirectory;
    
}

fileprivate func createPhysicsBody(_ dict: Dictionary<String, Any>, forDevice device: MTLDevice?) -> SCNPhysicsBody {
    var shape: SCNPhysicsShape?
    if let shapeDict = dict["shape"] as? Dictionary<String, Any>,
        let shapeGeometry = shapeDict["geometry"] as? Dictionary<String, Any> {
        let geometry = createGeometry(shapeGeometry, withDevice: device)
        shape = SCNPhysicsShape(geometry: geometry!, options: nil)
    }
    let type = dict["type"] as! Int
    let bodyType = SCNPhysicsBodyType(rawValue: type)
    let physicsBody = SCNPhysicsBody(type: bodyType!, shape: shape)
    if let categoryBitMack = dict["categoryBitMask"] as? Int {
        physicsBody.categoryBitMask = categoryBitMack
    }
    return physicsBody
}

fileprivate func createLight(_ dict: Dictionary<String, Any>) -> SCNLight {
    let light = SCNLight()
    if let type = dict["type"] as? Int {
        switch type {
        case 0:
            light.type = .ambient
            break
        case 1:
            light.type = .omni
            break
        case 2:
            light.type = .directional
            break
        case 3:
            light.type = .spot
            break
        case 4:
            light.type = .IES
            break
        case 5:
            light.type = .probe
            break
        case 6:
            if #available(iOS 13.0, *) {
                light.type = .area
            } else {
                // error
                light.type = .omni
            }
            break
        default:
            light.type = .omni
            break
        }
    } else {
        light.type = .omni
    }
    if let temperature = dict["temperature"] as? Double {
        light.temperature = CGFloat(temperature)
    }
    if let intensity = dict["intensity"] as? Double {
        light.intensity = CGFloat(intensity)
    }
    if let spotInnerAngle = dict["spotInnerAngle"] as? Double {
        light.spotInnerAngle = CGFloat(spotInnerAngle)
    }
    if let spotOuterAngle = dict["spotOuterAngle"] as? Double {
        light.spotOuterAngle = CGFloat(spotOuterAngle)
    }
    if let color = dict["color"] as? Int {
        light.color = UIColor(rgb: UInt(color))
    }
    return light
}
