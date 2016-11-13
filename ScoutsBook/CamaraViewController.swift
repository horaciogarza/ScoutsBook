//
//  CamaraViewController.swift
//  ScoutsBook
//
//  Created by Abraham Barcenas M on 11/12/16.
//  Copyright © 2016 Appdromeda. All rights reserved.
//
import UIKit
import Photos
import VisualRecognitionV3
import AWSCore
import AWSS3

class CamaraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var selectedImageUrl: URL?
    var selectedimage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        takePhoto()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func takePhoto(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        selectedImageUrl = info[UIImagePickerControllerReferenceURL] as? URL
        selectedimage = info[UIImagePickerControllerOriginalImage] as?  UIImage
        
        //startUploadingImage()
        
        if let imagen = info[UIImagePickerControllerOriginalImage] as? UIImage {
            //startUploadingImage(imagen : imagen)
            let newImage = imagen.resizeWith(percentage: 0.1)
            UIImageWriteToSavedPhotosAlbum(newImage!, self, #selector(self.getImageUrl(_:didFinishSavingWithError:contextInfo:)), nil)
            
            
            //dismiss(animated: true, completion: nil)
        }
    }
    
    func getImageUrl(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            if (fetchResult.firstObject != nil)
            {
                let lastImageAsset = fetchResult.firstObject! as PHAsset
                var name = fetchResult.firstObject?.value(forKey: "filename") as? String
                startUploadingImage(fileName: name!)
                /*lastImageAsset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (input, _) in
                    
                    //let url = input?.fullSizeImageURL
                    //self.startUploadingImage(url : url!)
                    //self.sendWatsonRequest(url : url!)
                }*/
            }
        }
    }
    

    
    
    func startUploadingImage(fileName:String)
    {
        /*var localFileName:String?
        if let imageToUploadUrl = selectedImageUrl
        {
            let phResult = PHAsset.fetchAssets(withALAssetURLs: [imageToUploadUrl], options: nil)
            localFileName = phResult.firstObject?.value(forKey: "filename") as? String
        }*/
        
        let ext = "png"
        let imageURL = Bundle.main.url(forResource: fileName, withExtension: ext)!
        
        /*if localFileName == nil
        {
            return
        }*/
        
        // Configure AWS Cognito Credentials
        let myIdentityPoolId = "us-east-1:b4b4b556-56b0-47cd-a4d1-71ddf06f4da0"
        
        let credentialsProvide:AWSCognitoCredentialsProvider = AWSCognitoCredentialsProvider(regionType: .usEast1, identityPoolId: myIdentityPoolId)
        
        let configuration = AWSServiceConfiguration(region:AWSRegionType.usEast1, credentialsProvider:credentialsProvide)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // Set up AWS Transfer Manager Request
        let S3BucketName = "image-items"
        let remoteName = fileName
        //let imageUrl = url
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.body = imageURL
        uploadRequest?.key = ProcessInfo.processInfo.globallyUniqueString + "." + ext
        uploadRequest?.bucket = S3BucketName
        uploadRequest?.contentType = "image/" + ext
        
        
        let transferManager = AWSS3TransferManager.default()
        
        // Perform file upload
        
        transferManager?.upload(uploadRequest).continue({ (task) -> Any? in
            if let error = task.error {
                print("Upload failed with error: (\(error.localizedDescription))")
            }
            
            if let exception = task.exception {
                print("Upload failed with exception (\(exception))")
            }
            
            if task.result != nil {
                
                let s3URL = URL(string: "https://s3.amazonaws.com/\(S3BucketName)/\(uploadRequest?.key!)")!
                print("Uploaded to:\n\(s3URL)")
                // Remove locally stored file
                //self.remoteImageWithUrl(uploadRequest.key!)
                
                DispatchQueue.main.async {
                    //self.displayAlertMessage()
                }
            }else {
                print("Unexpected empty result.")
            }
            return nil
            
            
        })
    }

    
    
    func generateImageUrl(fileName: String) -> NSURL{
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory().appendingFormat(fileName))
        let data = UIImageJPEGRepresentation(selectedimage!, 0.6)
        do{
            try data?.write(to: fileURL as URL, options: .atomic)
        }catch {
            print(error.localizedDescription)
        }
        
        
        return fileURL
    }
    
    
    
    
    
    
    func sendWatsonRequest(url : URL){
        
        let apiKey = "e9b2d83b02a794c8c61219fd956725815d55110a"
        let version = "2016-11-05" // use today's date for the most recent version
        let visualRecognition = VisualRecognition(apiKey: apiKey, version: version)
        
        var results : String = "Resultados de la imagen\n\n"
        visualRecognition.classify(image: url.description) { [unowned self] (classifiedImages) in
            
            
            for classification in classifiedImages.images[0].classifiers[0].classes{
                results = results + "Clasificacion: \(classification.classification) \n Probabilidad: \(classification.score) \n\n"
            }
            
            print(results)
            //dismiss(animated: true, completion: nil)
            //lo cambias al main para que se pueda mostrar, si no truena.
            DispatchQueue.main.async {
                //self.textView.text = results
            }
            
        }
    }
    
    
    /*
     // MARK: - Navigation
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}


extension UIImage {
    func resizeWith(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    func resizeWith(width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
}
