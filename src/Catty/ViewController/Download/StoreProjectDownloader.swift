/**
 *  Copyright (C) 2010-2020 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */

protocol StoreProjectDownloaderProtocol {
    func fetchProjects(forType: ProjectType, offset: Int, completion: @escaping (StoreProjectCollection.StoreProjectCollectionText?, StoreProjectDownloaderError?) -> Void)
    func fetchSearchQuery(searchTerm: String, completion: @escaping (StoreProjectCollection.StoreProjectCollectionNumber?, StoreProjectDownloaderError?) -> Void)
    func fetchProjectDetails(for project: StoreProject, completion: @escaping (StoreProject?, StoreProjectDownloaderError?) -> Void)
    func download(projectId: String, completion: @escaping (Data?, StoreProjectDownloaderError?) -> Void, progression: ((Float) -> Void)?)
}

final class StoreProjectDownloader: StoreProjectDownloaderProtocol {

    let session: URLSession
    var downloadProjectProgressObserver: NSKeyValueObservation?

    init(session: URLSession = StoreProjectDownloader.defaultSession()) {
        self.session = session
    }

    func fetchSearchQuery(searchTerm: String, completion: @escaping (StoreProjectCollection.StoreProjectCollectionNumber?, StoreProjectDownloaderError?) -> Void) {

        guard let indexURL = URL(string: String(format: "%@/%@?q=%@&%@%i&%@%i&%@%@",
                                                NetworkDefines.connectionHost,
                                                NetworkDefines.connectionSearch,
                                                searchTerm.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "",
                                                NetworkDefines.projectsLimit,
                                                NetworkDefines.searchStoreMaxResults,
                                                NetworkDefines.projectsOffset,
                                                0,
                                                NetworkDefines.maxVersion,
                                                Util.catrobatLanguageVersion()))
            else { return }

        self.session.dataTask(with: URLRequest(url: indexURL)) { data, response, error in
            let handleDataTaskCompletion: (Data?, URLResponse?, Error?) -> (items: StoreProjectCollection.StoreProjectCollectionNumber?, error: StoreProjectDownloaderError?)
            handleDataTaskCompletion = { data, response, error in
                if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut {
                    return (nil, .timeout)
                }

                guard let response = response as? HTTPURLResponse else { return (nil, .unexpectedError) }
                guard let data = data, response.statusCode == 200, error == nil else { return (nil, .request(error: error, statusCode: response.statusCode)) }
                let items: StoreProjectCollection.StoreProjectCollectionNumber?
                do {
                    items = try JSONDecoder().decode(StoreProjectCollection.StoreProjectCollectionNumber.self, from: data)
                } catch {
                    return (nil, .parse(error: error))
                }
                return (items, nil)
            }
            let result = handleDataTaskCompletion(data, response, error)
            DispatchQueue.main.async {
                completion(result.items, result.error)
            }
        }.resume()
    }

    func fetchProjects(forType: ProjectType, offset: Int, completion: @escaping (StoreProjectCollection.StoreProjectCollectionText?, StoreProjectDownloaderError?) -> Void) {

        let indexURL: URL
        let version: String = Util.catrobatLanguageVersion()

        switch forType {
        case .featured:
            let featuredUrl = "\(NetworkDefines.connectionHost)/\(NetworkDefines.connectionFeatured)?\(NetworkDefines.projectsLimit)\(NetworkDefines.chartProjectsMaxResults)"
            guard let url = URL(string: featuredUrl) else { return }
            indexURL = url

        case .mostDownloaded:
            guard let url = URL(string: "\(NetworkDefines.connectionHost)/\(NetworkDefines.connectionMostDownloaded)?\(NetworkDefines.projectsOffset)"
                + "\(offset)&\(NetworkDefines.projectsLimit)\(NetworkDefines.recentProjectsMaxResults)&\(NetworkDefines.maxVersion)\(version)") else { return }
            indexURL = url

        case .mostViewed:
            guard let url = URL(string: "\(NetworkDefines.connectionHost)/\(NetworkDefines.connectionMostViewed)?\(NetworkDefines.projectsOffset)"
                + "\(offset)&\(NetworkDefines.projectsLimit)\(NetworkDefines.recentProjectsMaxResults)&\(NetworkDefines.maxVersion)\(version)") else { return }
            indexURL = url

        case .mostRecent:
            guard let url = URL(string: "\(NetworkDefines.connectionHost)/\(NetworkDefines.connectionRecent)?\(NetworkDefines.projectsOffset)"
                + "\(offset)&\(NetworkDefines.projectsLimit)\(NetworkDefines.recentProjectsMaxResults)&\(NetworkDefines.maxVersion)\(version)") else { return }
            indexURL = url
        }

        self.session.dataTask(with: URLRequest(url: indexURL)) { data, response, error in
            let handleDataTaskCompletion: (Data?, URLResponse?, Error?) -> (items: StoreProjectCollection.StoreProjectCollectionText?, error: StoreProjectDownloaderError?)
            handleDataTaskCompletion = { data, response, error in
                if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut {
                    return (nil, .timeout)
                }

                guard let response = response as? HTTPURLResponse else { return (nil, .unexpectedError) }
                guard let data = data, response.statusCode == 200, error == nil else {
                    return (nil, .request(error: error, statusCode: response.statusCode))
                }
                let items: StoreProjectCollection.StoreProjectCollectionText?
                do {
                    items = try JSONDecoder().decode(StoreProjectCollection.StoreProjectCollectionText.self, from: data)
                } catch {
                    return (nil, .parse(error: error))
                }
                return (items, nil)
            }
            let result = handleDataTaskCompletion(data, response, error)
            DispatchQueue.main.async {
                completion(result.items, result.error)
            }

        }.resume()
    }

    func fetchProjectDetails(for project: StoreProject, completion: @escaping (StoreProject?, StoreProjectDownloaderError?) -> Void) {
        guard let indexURL = URL(string: "\(NetworkDefines.connectionHost)/\(NetworkDefines.connectionIDQuery)?id=\(project.projectId)") else { return }

        self.session.dataTask(with: URLRequest(url: indexURL)) { data, response, error in
            let handleDataTaskCompletion: (Data?, URLResponse?, Error?) -> (project: StoreProject?, error: StoreProjectDownloaderError?)
            handleDataTaskCompletion = { data, response, error in
                guard let response = response as? HTTPURLResponse else { return (nil, .unexpectedError) }

                guard let data = data, response.statusCode == 200, error == nil else {
                    let userInfo = ["projectId": project.projectId,
                                    "url": indexURL.absoluteString,
                                    "statusCode": response.statusCode,
                                    "error": error?.localizedDescription ?? ""] as [String: Any]

                    NotificationCenter.default.post(name: .projectFetchDetailsFailure, object: self, userInfo: userInfo)
                    return (nil, .request(error: error, statusCode: response.statusCode))
                }

                let collection: StoreProjectCollection.StoreProjectCollectionNumber?
                do {
                    collection = try JSONDecoder().decode(StoreProjectCollection.StoreProjectCollectionNumber.self, from: data)
                } catch {
                    return (nil, .parse(error: error))
                }
                return (collection?.projects.first, nil)
            }
            let result = handleDataTaskCompletion(data, response, error)
            DispatchQueue.main.async {
                completion(result.project, result.error)
            }
        }.resume()
    }

    static func defaultSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = Double(NetworkDefines.connectionTimeout)
        return URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    }
}

enum StoreProjectDownloaderError: Error {
    /// Indicates an error with the URLRequest.
    case request(error: Error?, statusCode: Int)
    /// Indicates a parsing error of the received data.
    case parse(error: Error)
    /// Indicates a server timeout.
    case timeout
    /// Indicates an unexpected error.
    case unexpectedError
}

enum ProjectType {
    case featured
    case mostDownloaded
    case mostViewed
    case mostRecent
}

extension StoreProjectDownloader {
    func download(projectId: String, completion: @escaping (Data?, StoreProjectDownloaderError?) -> Void, progression: ((Float) -> Void)?) {
        guard let indexURL = URL(string: "\(NetworkDefines.downloadUrl)/\(projectId).catrobat") else { return }

        let task = self.session.dataTask(with: URLRequest(url: indexURL)) { data, response, error in
            let handleDataTaskCompletion: (Data?, URLResponse?, Error?) -> (projectData: Data?, error: StoreProjectDownloaderError?)
            handleDataTaskCompletion = { data, response, error in
                guard let response = response as? HTTPURLResponse else { return (nil, .unexpectedError) }

                if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut {
                    return (nil, .timeout)
                }
                guard let data = data, response.statusCode == 200, error == nil else {
                    return (nil, .request(error: error, statusCode: response.statusCode)) }

                if let error = error {
                    return (nil, .parse(error: error))
                }

                return (data, nil)
            }

            let result = handleDataTaskCompletion(data, response, error)
            DispatchQueue.main.async {
                completion(result.projectData, result.error)
            }
        }

        if let progression = progression {
            downloadProjectProgressObserver = task.observe(\.countOfBytesReceived, options: [.new, .initial]) { progress, _ in
                var progress = Float(progress.countOfBytesReceived) / Float(progress.countOfBytesExpectedToReceive)
                if progress.isNaN {
                    progress = 0
                }
                progression(progress)
            }
        }

        task.resume()
    }
}
