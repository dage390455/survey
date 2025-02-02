import UIKit
import Flutter
import MAMapKit
import CityBase
//import shared_preferences
import Photos

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate,UIDocumentInteractionControllerDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
  var bascChanalpickImage:FlutterBasicMessageChannel!;
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    
//    CityPickersPlugin.register(with:self.registrar(forPlugin: "city_pickers"))
    
    AMapServices.shared().apiKey = "59b32dda2847efb5b44c249b24cc5e77";
    AMapServices.shared().enableHTTPS = true
    
    let flutterViewController = FlutterProjectListViewController.init(project: nil, nibName: nil, bundle: nil);
    if let flutterViewController = flutterViewController{
        flutterViewController.setModel(model: FLUTTER_PROJECT_LIST)//先设置页面，否则用到view会先进入viewDidLoad
        flutterViewController.splashScreenView =  FlutterSplashViewController().view
        flutterViewController.view.frame = UIScreen.main.bounds;
        let navigationC = RootNavController(rootViewController: flutterViewController)
        self.window?.rootViewController = navigationC
        
        //暂时写这里  后面整合到管理类
        let bascChanal = FlutterBasicMessageChannel(name: "BasicMessageChannelPlugin", binaryMessenger: flutterViewController, codec: FlutterStringCodec.init());
        
        let versionChanal = FlutterBasicMessageChannel(name: "BasicMessageGetVersionChannelPlugin", binaryMessenger: flutterViewController, codec: FlutterStringCodec.init());
        
        let cityChanal = FlutterBasicMessageChannel(name: "BasicMessageChannelPluginGetCity", binaryMessenger: flutterViewController);
        
        
        
        cityChanal.setMessageHandler{[weak self] (message, fr) in
            
            guard self != nil else { return }
            
            if message != nil {
                let mess = message as!String
//
//                if mess == "1"{
//                    let urlString = "https://fir.im/sensoroSurvey"
//
//                    let url = URL(string: urlString)
//
//                    UIApplication.shared.open(url!, options: ["":""], completionHandler: nil)
//                }else{
//                    let infoDictionary = Bundle.main.infoDictionary!
//                    let majorVersion = infoDictionary["CFBundleShortVersionString"]//主程序版本号
//                    let appVersion = majorVersion as! String
//                    versionChanal.sendMessage(appVersion)
//                }
             let postion = UIStoryboard.init(name: "cityPic", bundle: nil).instantiateViewController(withIdentifier: "SelectCityViewController") as! SelectCityViewController;
                 postion.modalPresentationStyle = .overFullScreen;
                 postion.returnTextBlock = { [weak self] (selet)->Void in
                    guard self != nil else {return;}
                  
                    cityChanal.sendMessage(selet)
                }
              flutterViewController.present(postion, animated: true, completion: nil)//进入照相界面
                
            }
            
            
        }
        
        
        versionChanal.setMessageHandler{[weak self] (message, fr) in
            
            guard self != nil else { return }
            
            if message != nil {
                let mess = message as!String
                
                if mess == "1"{
                    let urlString = "https://fir.im/sensoroSurvey"
                    
                    let url = URL(string: urlString)
                    
                    UIApplication.shared.open(url!, options: ["":""], completionHandler: nil)
                }else{
                    let infoDictionary = Bundle.main.infoDictionary!
                    let majorVersion = infoDictionary["CFBundleShortVersionString"]//主程序版本号
                    let appVersion = majorVersion as! String
                    versionChanal.sendMessage(appVersion)
                }
            }
            
           
        }
        
        bascChanal.setMessageHandler { [weak self] (message, fr) in
            guard let self = self else { return }
            
            if  message != nil {
                let loction = message as!String
                let list =  loction.components(separatedBy: ",");
                
                if(CLLocationManager.authorizationStatus() != .denied) {
                    
                    let postion = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationEditController") as! LocationEditController;
                    
                    if list.count == 4 {
                        if list[0] == "1"{
                            postion.readOnly = true;
                        }else{
                            postion.readOnly = false;
                        }
                        if list[1].count > 0 {
                            postion.lat = Double(list[1])!
                            postion.lon = Double(list[2])!
                            postion.repositionDeviceOnly = true
                        }
                    }
                    postion.completion = { [weak self] (lat,lon, address, channelMask)->Void in
                        guard self != nil else {return;}
                        let loction = "\(lat),\(lon),\(address)"
                        bascChanal.sendMessage(loction)
                    }
                    navigationC.pushViewController(postion, animated: true);
                    
                }else{
                    SVProgressHUD.showError(withStatus: "请到设置页面打开定位权限")
                }
            }
            
           
        }
      
        bascChanalpickImage = FlutterBasicMessageChannel(name: "BasicMessageChannelPluginPickImage", binaryMessenger: flutterViewController, codec: FlutterStringCodec.init());
        
        bascChanalpickImage.setMessageHandler { [weak self] (message, fr) in
            guard let self = self else { return }
            
//            let postion = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationEditController") as! LocationEditController;
//
//            postion.completion = { [weak self] (lat,lon, address, channelMask)->Void in
//                guard self != nil else {return;}
//
//                bascChanal.sendMessage(address)
//            }
//            navigationC.pushViewController(postion, animated: true);
            fr("swift 传值成功")
            
            
            
            var sourceType = UIImagePickerControllerSourceType.camera
             let mess = message as! String
                if(mess == "1"){
                    sourceType = UIImagePickerControllerSourceType.photoLibrary
                }
            
            
            if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
                sourceType = UIImagePickerControllerSourceType.photoLibrary
            }

            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = sourceType
    
            flutterViewController.present(picker, animated: true, completion: nil)//进入照相界面
        }
    }
    
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        print(url.absoluteString)
       
        NotificationCenter.default.post(name: NSNotification.Name("flutter_open_file"), object: self, userInfo: ["url":url.absoluteString])
        
//        DocumentManagerViewController.openFileAndSave(url.absoluteString);
        return true;
    }
    

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image:UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
       
       
        let home = NSHomeDirectory() as NSString
        //打印沙盒路径,可以前往文件夹看到你下载好的图片
        print(home)
        let docPath = home.appendingPathComponent("Documents") as NSString
        let filePath = docPath.appendingPathComponent(getCurrentId()+"666.png")
        do {
            try UIImagePNGRepresentation(image)?.write(to: URL(fileURLWithPath: filePath),options: NSData.WritingOptions.atomic)
            bascChanalpickImage.sendMessage(filePath)
//            writeToFile(filePath, options: NSData.WritingOptions.DataWritingAtomic)
        }catch {
            print(error)
        }
        picker.dismiss(animated: true, completion: nil)

    }

    func getCurrentId() -> String {
        let now = NSDate()
        let timeInterval:TimeInterval = now.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        return "\(timeStamp)"
    }

    
    
    
 // 微信开放平台  AppID：wxa6699198d77a32f2   e4f935b68806e2d49ba31cd0f3ae33ef  Bundle ID：com.sensoro.survey1
 // 微信开放平台  AppID：wxf274fbb694ee5981  c63730e77d8a95a0670a161a053814f0  Bundle ID：com.sensoro.survey
}


