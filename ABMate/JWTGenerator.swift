//
//  JWTGenerator.swift
//  ABMate
//
//  © Created by Somesh Pathak on 23/06/2025.
//


import Foundation
import CryptoKit

class JWTGenerator {
    static func createClientAssertion(credentials: APICredentials) throws -> String {
        
        let privateKey = try parsePrivateKey(credentials.privateKey)
        
        // Create JWT header
        let header = """
        {"alg":"ES256","kid":"\(credentials.keyId)","typ":"JWT"}
        """
        
        // Create JWT payload
        let now = Int(Date().timeIntervalSince1970)
        let exp = now + (180 * 24 * 60 * 60) // 180 days
        
        let payload = """
        {"sub":"\(credentials.clientId)","aud":"https://account.apple.com/auth/oauth2/v2/token","iat":\(now),"exp":\(exp),"jti":"\(UUID().uuidString)","iss":"\(credentials.clientId)"}
        """
        
        // Base64URL encode
        let headerBase64 = header.data(using: .utf8)!.base64URLEncoded()
        let payloadBase64 = payload.data(using: .utf8)!.base64URLEncoded()
        
        // Create signature
        let signingInput = "\(headerBase64).\(payloadBase64)"
        let signature = try privateKey.signature(for: signingInput.data(using: .utf8)!)
        
        // Convert signature to base64URL
        let signatureBase64 = signature.rawRepresentation.base64URLEncoded()
        
        return "\(signingInput).\(signatureBase64)"
    }
    
    private static func parsePrivateKey(_ pemString: String) throws -> P256.Signing.PrivateKey {
        // Remove PEM headers and whitespace
        let base64String = pemString
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        guard let derData = Data(base64Encoded: base64String) else {
            throw NSError(domain: "JWT", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid base64"])
        }
        
        
        if let key = try? P256.Signing.PrivateKey(derRepresentation: derData) {
            return key
        }
        
        
        if derData.count > 26 {
            // Skip PKCS#8 header for P-256 keys
            let keyData = derData.subdata(in: 36..<derData.count)
            if let key = try? P256.Signing.PrivateKey(x963Representation: keyData) {
                return key
            }
        }
        
        
        if derData.count == 32 {
            return try P256.Signing.PrivateKey(rawRepresentation: derData)
        }
        
        throw NSError(domain: "JWT", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to parse private key"])
    }
}

extension Data {
    func base64URLEncoded() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
