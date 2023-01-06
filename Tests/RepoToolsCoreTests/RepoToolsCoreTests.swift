import XCTest
import Nimble
import struct ShellOut.ShellOutError
@testable import RepoToolsCore
 
final class RepoToolsCoreTests: XCTestCase {
	
	var calls: [(command: String, arguments: [String], at: String, process: Process, outputHandle: FileHandle?, errorHandle: FileHandle?)]!
	var nextResponse: () throws -> String = { "" }
	
	override func setUp() {
		super.setUp()
		calls = []
		nextResponse = { "" }
	}
	
	private func fakeShellOut(
		to command: String,
		arguments: [String] = [],
		at path: String = ".",
		process: Process = .init(),
		outputHandle: FileHandle? = nil,
		errorHandle: FileHandle? = nil
	) throws -> String {
		calls += [(command, arguments, path, process, outputHandle, errorHandle)]
		return try nextResponse()
	}
	
	func testPush() throws {
		
		let git = Git(provider: fakeShellOut)
		try git.push(branch: .stubBranch, remote: .stubRemote, workingDirectory: .stubWorkingDirectory)
		
		expect(self.calls.count) == 2
		expect(self.calls[0].command) == "git"
		expect(self.calls[0].arguments) == ["push", "my-remote", "my-branch"]
		expect(self.calls[0].at) == "/some-path"

		expect(self.calls[1].command) == "git"
		expect(self.calls[1].arguments) == ["lfs push", "my-remote", "--all"]
		expect(self.calls[1].at) == "/some-path"
	}
	
	func testWorkingDirectoryIsPorcelainTrue() throws {
		
		let git = Git(provider: fakeShellOut)
		
		nextResponse = { "" }
		expect(try git.workingDirectoryIsPorcelain(.stubWorkingDirectory)) == true
		
		expect(self.calls.count) == 1
		expect(self.calls[0].command) == "git"
		expect(self.calls[0].arguments) == ["status --porcelain"]
		expect(self.calls[0].at) == "/some-path"
	}
	
	func testWorkingDirectoryIsPorcelainFalse() throws {
		
		let git = Git(provider: fakeShellOut)
		
		nextResponse = { " M Package.resolved" }
		expect(try git.workingDirectoryIsPorcelain(.stubWorkingDirectory)) == false
		
		expect(self.calls.count) == 1
		expect(self.calls[0].command) == "git"
		expect(self.calls[0].arguments) == ["status --porcelain"]
		expect(self.calls[0].at) == "/some-path"
	}
	
	func testHasRemoteTrue() throws {

		let git = Git(provider: fakeShellOut)
		
		nextResponse = { "git@github.com:minvws/nl-covid19-coronacheck-app-ios-private" }
		expect(try git.hasRemote(remote: .stubRemote, workingDirectory: .stubWorkingDirectory)) == true
		
		XCTAssertEqual(calls.count, 1)
		expect(self.calls[0].command) == "git"
		expect(self.calls[0].arguments) == ["config remote.my-remote.url"]
		expect(self.calls[0].at) == "/some-path"
	}
	
	func testHasRemoteFalse() throws {

		let git = Git(provider: fakeShellOut)
		
		nextResponse = { "" }
		expect(try git.hasRemote(remote: .stubRemote, workingDirectory: .stubWorkingDirectory)) == false
		
		expect(self.calls.count) == 1
		expect(self.calls[0].command) == "git"
		expect(self.calls[0].arguments) == ["config remote.my-remote.url"]
		expect(self.calls[0].at) == "/some-path"
	}

	func testAddRemote() throws {

		let git = Git(provider: fakeShellOut)

		try git.addRemote(remote: .stubRemote, workingDirectory: .stubWorkingDirectory)
		
		expect(self.calls.count) == 1
		expect(self.calls[0].command) == "git"
		expect(self.calls[0].arguments) == ["remote add my-remote git@github.com:org/repo"]
		expect(self.calls[0].at) == "/some-path"
	}

	func testFetchRepo() throws {

		let git = Git(provider: fakeShellOut)
		try git.fetchRepo(remote: .stubRemote, workingDirectory: .stubWorkingDirectory)

		expect(self.calls.count) == 2
		expect(self.calls[0].command) == "git"
		expect(self.calls[0].arguments) == ["fetch my-remote"]
		expect(self.calls[0].at) == "/some-path"

		expect(self.calls[1].command) == "git"
		expect(self.calls[1].arguments) == ["lfs fetch my-remote --all"]
		expect(self.calls[1].at) == "/some-path"
	}

	func testCreateSyncBranch() throws {

		let git = Git(provider: fakeShellOut)

		let syncBranch = try git.createSyncBranch(workingDirectory: .stubWorkingDirectory, now: Date(timeIntervalSince1970: 1673008322))

		expect(syncBranch.name) == "sync/2023106-013202"
		
		expect(self.calls.count) == 1
		expect(self.calls[0].command) == "git"
		expect(self.calls[0].arguments) == ["branch sync/2023106-013202 private-repo/main"]
		expect(self.calls[0].at) == "/some-path"
	}

	func test() throws {

		let git = Git(provider: fakeShellOut)

		try git.pushAllReleaseTags(remote: .stubRemote, workingDirectory: .stubWorkingDirectory)

		let expected = #"""
			git show-ref --tags | grep -v -F "$(git ls-remote --tags my-remote | grep -v '\^{}' | cut -f 2)" | grep -e "Holder-" -e "Verifier-" | grep -v "\-RC" | cut -f2 -d " " | xargs -L1 git push my-remote
			"""#
		
		expect(self.calls.count) == 1
		expect(self.calls[0].command) == expected
		expect(self.calls[0].arguments) == []
		expect(self.calls[0].at) == "/some-path"
	}
}

extension Remote {
	
	static var stubRemote: Remote {
		Remote(name: "my-remote", repo: try! GithubRepo(path: "org/repo"))
	}
}

extension Branch {
	
	static var stubBranch: Branch {
		Branch(name: "my-branch")
	}
}

extension URL {
	
	static var stubWorkingDirectory: URL {
		URL(string: "/some-path")!
	}
}
