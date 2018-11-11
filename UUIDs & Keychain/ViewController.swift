//
//  ViewController.swift
//  UUIDs & Keychain
//
//  Created by kidnapper on 2018/11/11.
//  Copyright © 2018 kidnapper. All rights reserved.
//

import UIKit

import AdSupport

enum StoreStatus: String {
    case firstTimeSuccess = "first time save successfully"
    case firstTimeFailed = "first time save failed"
    case updateSuccess = "update successfully"
    case updateFailed = "update failed"
    
    func textColor() -> UIColor {
        switch self {
        case .firstTimeSuccess,
             .updateSuccess:
            return UIColor.green
        case .firstTimeFailed,
             .updateFailed:
            return UIColor.red
        }
    }
}

class ViewController: UIViewController {
    
    // put your teamID + bundleID here
    // e.g. "9SW8D3NIPB.kidnapper.UniqueIdentifier"
    // https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/AppID.html
    let accessGroup = "kidnapper.UUIDs---Keychain"
    private let idfa: String = "idfa"
    private let idfv: String = "idfv"
    
    @IBOutlet weak var idfaButton: UIButton!
    @IBOutlet weak var idfvButton: UIButton!
    @IBOutlet weak var oldIdfa: CopyableLabel!
    @IBOutlet weak var newIdfa: CopyableLabel!
    @IBOutlet weak var oldIdfv: CopyableLabel!
    @IBOutlet weak var newIdfv: CopyableLabel!
    
    @IBOutlet weak var keychainSaveButton: UIButton!
    @IBOutlet weak var keychainInputTextField: UITextField!
    @IBOutlet weak var saveStatusLabel: CopyableLabel!
    @IBOutlet weak var keychainGetButton: UIButton!
    @IBOutlet weak var keychainResultLabel: CopyableLabel!
    
    @IBAction func clickIdfa(_ sender: Any) {
        let idfa: String = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        newIdfa.text = idfa
        UserDefaults.standard.set(idfa, forKey: self.idfa)
    }
    
    @IBAction func clickIdfv(_ sender: Any) {
        let idfv: String? = UIDevice.current.identifierForVendor?.uuidString
        newIdfv.text = idfv
        UserDefaults.standard.set(idfv, forKey: self.idfv)
    }
    
    @IBAction func clickSave(_ sender: Any) {
        if let text = keychainInputTextField.text, !text.isEmpty {
            let status: StoreStatus = saveToKeychain(text)
            saveStatusLabel.text = status.rawValue
            saveStatusLabel.textColor = status.textColor()
        } else {
            saveStatusLabel.text = "no input"
            saveStatusLabel.textColor = .red
        }
    }
    
    @IBAction func clickGet(_ sender: Any) {
        if let text = getFromKeychain() {
            keychainResultLabel.text = text
            keychainResultLabel.textColor = .black
        } else {
            keychainResultLabel.text = "no result"
            keychainResultLabel.textColor = .red
        }
    }
    
    @IBAction func deleteKeychainData(_ sender: Any) {
        var query = [String : AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = "service" as AnyObject?
        query[kSecAttrAccount as String] = "account" as AnyObject?
        
        // must switch on keychain sharing in capabilities
        query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        
        SecItemDelete(query as CFDictionary)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        keychainInputTextField.delegate = self
        
        if let idfa: String = UserDefaults.standard.value(forKey: self.idfa) as? String {
            oldIdfa.text = idfa
        } else {
            oldIdfa.text = "not save yet"
        }
        oldIdfa.sizeToFit()
        
        if let idfv: String = UserDefaults.standard.value(forKey: self.idfv) as? String {
            oldIdfv.text = idfv
        } else {
            oldIdfv.text = "not save yet"
        }
        oldIdfv.sizeToFit()
    }
    
    func saveToKeychain(_ string: String) -> StoreStatus {
        let encodedPassword: Data = string.data(using: String.Encoding.utf8)!
        
        if getFromKeychain() != nil {
            // already have one
            var attributesToUpdate = [NSString : AnyObject]()
            attributesToUpdate[kSecValueData as NSString] = encodedPassword as AnyObject?
            
            let query = keychainQuery() as CFDictionary
            
            let status = SecItemUpdate(query, attributesToUpdate as CFDictionary)
            guard status == noErr else { return .updateFailed }
            return .updateSuccess
        } else {
            // first time
            var newItem = keychainQuery()
            newItem[kSecValueData as String] = encodedPassword as AnyObject
            SecItemDelete(newItem as CFDictionary)
            
            let status = SecItemAdd(newItem as CFDictionary, nil)
            guard status == noErr else { return .firstTimeFailed }
            return .firstTimeSuccess
        }
    }
    
    func getFromKeychain() -> String? {
        
        var query = keychainQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        var queryResult: AnyObject?
        
        let status = withUnsafeMutablePointer(to: &queryResult) { pointer -> OSStatus in
            return SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer(pointer))
        }
        
        guard status != errSecItemNotFound else { return nil }
        guard status == noErr else { return nil }
        
        guard let existingItem = queryResult as? [String : AnyObject],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8) else { return nil }
        
        return password
    }
    
    func keychainQuery() -> [String : AnyObject] {
        var query = [String : AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = "service" as AnyObject?
        query[kSecAttrAccount as String] = "account" as AnyObject?
        
        // must switch on keychain sharing in capabilities
        query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        return query
    }
    
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
}
