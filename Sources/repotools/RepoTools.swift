/*
* Copyright (c) 2022 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import ArgumentParser
import Foundation

@main
struct RepoTools: ParsableCommand {
	static var configuration = CommandConfiguration(
		abstract: "A collection of tools from RDO for working with a git repository.",
		subcommands: [SyncRepo.self]
	)
}
