// Created by Lunar on 22/06/2022.
//

import SwiftUI
import Combine

struct DownloadableImage: View {
    @StateObject var imageLoader: ImageLoader
    
    init(url: URL) {
        _imageLoader = .init(wrappedValue: ImageLoader(url: url))
    }
    
    var body: some View {
        switch imageLoader.image {
        case .success(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        case .failure:
            VStack(alignment: .center) {
                Image(systemName: "exclamationmark.triangle")
                    .frame(width: 80, height: 80, alignment: .center)
                    .font(.system(size: 30))
                    .foregroundColor(.aircastingGray)
                Text("Failed to load the image")
            }
        case .none:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .padding(.vertical)
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: Result<UIImage, Error>?
    
    struct NoImageError: Error { }

    init(url: URL) {
        guard !url.isFileURL else {
            loadImageFromFile(url)
            return
        }
        
        loadImageFromWeb(url)
    }
    
    private func loadImageFromFile(_ url: URL) {
        DispatchQueue.global().async {
            let result: Result<UIImage, Error> = {
                let image = UIImage(contentsOfFile: url.path)
                return image != nil ? .success(image!) : .failure(NoImageError())
            }()
            
            DispatchQueue.main.async {
                self.image = result
            }
        }
    }
    
    private func loadImageFromWeb(_ url: URL) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.image = .failure(NoImageError())
                }
                return
            }
            DispatchQueue.main.async {
                self.image = .success(image)
            }
        }
        task.resume()
    }
}
