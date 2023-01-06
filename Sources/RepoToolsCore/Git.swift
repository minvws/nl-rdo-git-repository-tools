/*
* Copyright (c) 2022 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import struct ShellOut.ShellOutError

public struct Git {
	
	private let provider: (
		String, // to:
		[String], // arguments:
		String, // at:
		Process, // process:
		FileHandle?, // outputHandle:
		FileHandle? // errorHandle:
	) throws -> String
		
	/// - Parameter provider: i.e. the `shellOut()` function from module `ShellOut`. See ShellOut.shellOut() for more info.
	public init(provider: @escaping (String, [String], String, Process, FileHandle?, FileHandle?) throws -> String) {
		self.provider = provider
	}

	@discardableResult
	private func shellOut(
		to command: String,
		arguments: [String] = [],
		at path: String = ".",
		process: Process = .init(),
		outputHandle: FileHandle? = nil,
		errorHandle: FileHandle? = nil
	) throws -> String {
		try provider(command, arguments, path, process, outputHandle, errorHandle)
	}
	
	public func push(branch: Branch, remote: Remote, workingDirectory: URL) throws {
		// TODO: this could be optimized to only push if there actually are changes between the two branches (if not, this currently creates an empty PR)
		print("🚚 Pushing \(branch.name) to \(remote.name)")
		try shellOut(to: "git", arguments: ["push", remote.name, branch.name], at: workingDirectory.path)
		try shellOut(to: "git", arguments: ["lfs push", remote.name, "--all"], at: workingDirectory.path)
	}
	
	/// - Returns: Whether the working directory has any changes, according to git.
	public func workingDirectoryIsPorcelain(_ workingDirectory: URL) throws -> Bool {
		return try shellOut(to: "git", arguments: ["status --porcelain"], at: workingDirectory.path).isEmpty
	}
	
	/// - Returns: Whether the git repo in the given directory has a `remote` matching the passed parameter.
	public func hasRemote(remote: Remote, workingDirectory: URL) throws -> Bool {
		do {
			return try !shellOut(to: "git", arguments: ["config remote.\(remote.name).url"], at: workingDirectory.path).isEmpty
		}
		catch let error as ShellOutError where error.terminationStatus == 1 {
			// exit code of 1 indicates that it didn't find the remote but didn't fail.
			return false
		}
	}
	
	/// `git remote add [given remote]`
	public func addRemote(remote: Remote, workingDirectory: URL) throws {
		_ = try shellOut(to: "git", arguments: ["remote add \(remote.name) git@github.com:\(remote.repo.path)"], at: workingDirectory.path).isEmpty
		print("➕ Remote `\(remote.name)` added at github: `\(remote.repo.path)`")
	}
	
	/// Fetches the given remote, also fetching LFS.
	public func fetchRepo(remote: Remote, workingDirectory: URL) throws {
		print("🔄 Ensuring we are in sync with `\(remote.name)`")
		try shellOut(to: "git", arguments: ["fetch \(remote.name)"], at: workingDirectory.path)
		try shellOut(to: "git", arguments: ["lfs fetch \(remote.name) --all"], at: workingDirectory.path)
	}
	
	/// Create a branch based on `main` with a timestamp branch name.
	/// - Returns: the created Branch.
	public func createSyncBranch(workingDirectory: URL, now: Date = Date()) throws -> Branch {
		// "20221230-111743"
		let timestamp = {
			let df = DateFormatter()
			df.dateFormat = "yyyyMdd-hhmmss"
			return df.string(from: now)
		}()
		
		print("🐣 Creating a new sync branch based on private/main")
		
		let branchName = "sync/\(timestamp)"
		try shellOut(to: "git", arguments: ["branch \(branchName) private-repo/main"], at: workingDirectory.path)
		
		return Branch(name: branchName)
	}
	
	/// Pushes all the local tags to the given remote
	/// - Parameters:
	///   - remote: where we're pushing the tags to
	///   - workingDirectory: the directory containing a git repo
	///   - matchingGrepPatterns: an array of `grep -e` patterns which tags must conform to at-least-one of to be included in what's pushed.
	///   - strippingGrepPattern: a `grep -v` pattern which - if matched - will exclude a tag.
	public func pushAllReleaseTags(remote: Remote, workingDirectory: URL, matchingGrepPatterns: [String]? = nil, strippingGrepPattern: String? = nil) throws  {
		
		var commandFragments: [String] = []
		
		// get all hash/tag in pairs like "62578f6 refs/tags/2.1.3-Holder"
		commandFragments += [#"git show-ref --tags"#]
		// Match only those that don't appear on `remote`
		commandFragments += [#"grep -v -F "$(git ls-remote --tags \#(remote.name) | grep -v '\^{}' | cut -f 2)""#]
		
		// Match only those that fit a `grep -e` pattern:
		if let matchingGrepPatterns, !matchingGrepPatterns.isEmpty {
			
			let matchGrepCommand = matchingGrepPatterns
				.map { #" -e "\#($0)""# }
				.joined()
			
			// grep -e "Holder-" -e "Verifier-"
			commandFragments += [#"grep\#(matchGrepCommand)"#]
		}

		// Strip out pattern
		if let strippingGrepPattern, !strippingGrepPattern.isEmpty {
			commandFragments += [#"grep -v "\#(strippingGrepPattern)""#]
		}
		
		// Get the tag name, drop the hash.
		commandFragments += [#"cut -f2 -d " ""#]
		// Finally push each tag to `public-repo` remote.
		commandFragments += [#"xargs -L1 git push \#(remote.name)"#]
		
		let command = commandFragments.joined(separator: " | ")
		
		// execute:
		try shellOut(to: command, at: workingDirectory.path)
	}
}

extension Remote {
	
	public func addIfNeeded(workingDirectory: URL, git: Git) throws {
		if try !git.hasRemote(remote: self, workingDirectory: workingDirectory) {
			try git.addRemote(remote: self, workingDirectory: workingDirectory)
		}
	}
}
