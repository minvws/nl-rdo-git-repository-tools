@main
public struct SyncRepo {
    public private(set) var text = "Hello, World!"

    public static func main() {
        print(SyncRepo().text)
    }
}
