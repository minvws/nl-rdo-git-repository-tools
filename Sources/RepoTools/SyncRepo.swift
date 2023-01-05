/*
* Copyright (c) 2022 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import ArgumentParser
import ShellOut
import RepoToolsCore

extension RepoTools {
	
	struct SyncRepo: ParsableCommand {
	
		static var configuration = CommandConfiguration(
			abstract: """
	  A utility for syncing the changes from a private repository to a public repository, for
	  when a development team works on the repository in a private fork (for reasons of compliance
	  with existing processes) and wants to share its work.
	  """
		)
		
		@Option(
			name: [.customLong("public-github-path", withSingleDash: false)],
			help: ArgumentHelp("The github path of the public repo, e.g. `minvws/nl-covid19-coronacheck-app-ios`", valueName: "path"),
			transform: GithubRepo.init)
		var publicGithubRepo: GithubRepo
		
		@Option(
			name: [.customLong("private-github-path", withSingleDash: false)],
			help: ArgumentHelp("The github path of the private repo, e.g. `minvws/nl-covid19-coronacheck-app-ios-private`", valueName: "path"),
			transform: GithubRepo.init)
		var privateGithubRepo: GithubRepo
		
		// `workingDirectory.path` is what we want
		@Argument(help: "The working directory", transform: { string in
			let url = URL(fileURLWithPath: string, isDirectory: true)
			return url
		})
		var workingDirectory: URL
		
		mutating func validate() throws {
			// Verify the folder actually exists:
			guard FileManager.default.fileExists(atPath: workingDirectory.path), workingDirectory.hasDirectoryPath else {
				throw ValidationError("🧾 Folder does not exist at \(workingDirectory.path)")
			}
		}
		
		mutating func run() throws {
			guard try Git.workingDirectoryIsPorcelain(workingDirectory) else { throw ValidationError("""
	🧾 Your working directory contains changes.
	To avoid losing changes, this script only works if you have a clean directory.
	Commit any work to the current branch, and try again.
	"""
			) }
			
			let publicRemote = Remote(name: "public-repo", repo: publicGithubRepo)
			try publicRemote.addIfNeeded(workingDirectory: workingDirectory)
			
			let privateRemote = Remote(name: "private-repo", repo: privateGithubRepo)
			try privateRemote.addIfNeeded(workingDirectory: workingDirectory)
			
			try Git.fetchRepo(remote: privateRemote, workingDirectory: workingDirectory)
			
			let syncBranch = try Git.createSyncBranch(workingDirectory: workingDirectory)
			
			try Git.push(branch: syncBranch, remote: publicRemote, workingDirectory: workingDirectory)
			
			try Git.pushAllReleaseTags(remote: publicRemote, workingDirectory: workingDirectory)
			
			// Create a PR:
			print("✅ Constructing a PR request and opening it in the browser")
			let pullRequestURL = "https://github.com/\(publicRemote.repo.path)/compare/\(syncBranch.name)?quick_pull=1&title=Sync+public+repo+from+private+repository&body=This+PR+proposes+the+latest+changes+from+private+to+public+repository."
			try shellOut(to: "open", arguments: [pullRequestURL])
		}
	}
}