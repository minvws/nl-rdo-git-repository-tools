/*
* Copyright (c) 2022 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// Represents a git "remote", as in `git show remote origin`
public struct Remote {
	public let name: String
	public let repo: GithubRepo
	
	public init(name: String, repo: GithubRepo) {
		self.name = name
		self.repo = repo
	}
}

/// Represents a git "branch"
public struct Branch {
	public let name: String
	
	public init(name: String) {
		self.name = name
	}
}

/// Represents a github repository path
public struct GithubRepo {
	
	public let path: String
	public let organisation: String
	public let repository: String
	
	private static let matchRegex = #/\A([\w-]+)/([\w-]+)\z/#
	
	/// Path should have format `minvws/nl-covid19-coronacheck-app-ios`
	public init(path: String) throws {
		
		// Check the path has correct format:
		guard let result = path.firstMatch(of: GithubRepo.matchRegex)
		else { throw "🧾 Provide a valid github path e.g. `minvws/nl-covid19-coronacheck-app-ios`" }
		
		self.path = String(result.0) // `minvws/nl-covid19-coronacheck-app-ios`
		self.organisation = String(result.1) // `minvws`
		self.repository = String(result.2) // `nl-covid19-coronacheck-app-ios`
	}
}
