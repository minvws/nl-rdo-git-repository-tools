/*
* Copyright (c) 2022 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import ShellOut

public enum Git {
	
	public static func push(branch: Branch, remote: Remote, workingDirectory: URL) throws {
		// TODO: this could be optimized to only push if there actually are changes between the two branches (if not, this currently creates an empty PR)
		print("🚚 Pushing \(branch.name) to \(remote.name)")
		try shellOut(to: "git", arguments: ["push", remote.name, branch.name], at: workingDirectory.path)
		try shellOut(to: "git", arguments: ["lfs push", remote.name, "--all"], at: workingDirectory.path)
	}
	
	public static func workingDirectoryIsPorcelain(_ workingDirectory: URL) throws -> Bool {
		return try shellOut(to: "git", arguments: ["status --porcelain"], at: workingDirectory.path).isEmpty
	}
	
	public static func hasRemote(remote: Remote, workingDirectory: URL) throws -> Bool {
		do {
			return try !shellOut(to: "git", arguments: ["config remote.\(remote.name).url"], at: workingDirectory.path).isEmpty
		}
		catch let error as ShellOutError where error.terminationStatus == 1 {
			// exit code of 1 indicates that it didn't find the remote
			return false
		}
	}
	
	public static func addRemote(remote: Remote, workingDirectory: URL) throws {
		_ = try shellOut(to: "git", arguments: ["remote add \(remote.name) git@github.com:\(remote.repo.path)"], at: workingDirectory.path).isEmpty
		print("➕ Remote `\(remote.name)` added at github: `\(remote.repo.path)`")
	}
	
	public static func fetchRepo(remote: Remote, workingDirectory: URL) throws {
		print("🔄 Ensuring we are in sync with `\(remote.name)`")
		try shellOut(to: "git", arguments: ["fetch \(remote.name)"], at: workingDirectory.path)
		try shellOut(to: "git", arguments: ["lfs fetch \(remote.name) --all"], at: workingDirectory.path)
	}
	
	public static func createSyncBranch(workingDirectory: URL) throws -> Branch {
		// "20221230-111743"
		let timestamp = {
			let df = DateFormatter()
			df.dateFormat = "yyyyMdd-hhmmss"
			return df.string(from: Date())
		}()
		
		print("🐣 Creating a new sync branch based on private/main")
		
		let branchName = "sync/\(timestamp)"
		try shellOut(to: "git", arguments: ["branch \(branchName) private-repo/main"], at: workingDirectory.path)
		
		return Branch(name: branchName)
	}
	
	public static func pushAllReleaseTags(remote: Remote, workingDirectory: URL) throws  {
		
		var commandFragments: [String] = []
		
		// get all hash/tag in pairs like "62578f6 refs/tags/2.1.3-Holder"
		commandFragments += [#"git show-ref --tags"#]
		// Match only those that don't appear on `public-repo`
		commandFragments += [#"grep -v -F "$(git ls-remote --tags \#(remote.name) | grep -v '\^{}' | cut -f 2)""#]
		// Match only those that are in our release tag format
		commandFragments += [#"grep -e "Holder-" -e "Verifier-""#]
		// Strip out the RCs
		commandFragments += [#"grep -v "\-RC""#]
		// Get the tag name, drop the hash.
		commandFragments += [#"cut -f2 -d " ""#]
		// Finally push each tag to `public-repo` remote.
		commandFragments += [#"xargs -L1 git push \#(remote.name)"#]
		
		let command = commandFragments.joined(separator: " | ")
		
		// execute:
		try shellOut(to: ShellOutCommand(string: command), at: workingDirectory.path)
	}
}

extension Remote {
	
	public func addIfNeeded(workingDirectory: URL) throws {
		if try !Git.hasRemote(remote: self, workingDirectory: workingDirectory) {
			try Git.addRemote(remote: self, workingDirectory: workingDirectory)
		}
	}
}
