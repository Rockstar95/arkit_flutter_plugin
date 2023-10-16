import Foundation

class HttpDownloader {
    func downloadFileAsync(fileURLString: String, filePathString: String?) async throws -> URL {
        
        guard let url = URL(string: fileURLString) else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: nil);
        }
        
        do {
            let (downloadedUrl, _) = try await URLSession.shared.download(from: url);
            
            print("Download Url:", downloadedUrl.absoluteString);
//            print("Download Response:", response);
//            print(response!);
//            print(url!);
            
            return downloadedUrl;
        } catch {
            throw error;
        }
    }
}
