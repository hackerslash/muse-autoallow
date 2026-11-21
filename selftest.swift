#if SELFTEST
@main enum SelfTest {
    static func main() {
        let p = parseUpload("Vondu wants to upload mdafridisk_ai.pdf to coditude.keka.com. This task comes from the side chat")
        precondition(p?.file == "mdafridisk_ai.pdf" && p?.site == "coditude.keka.com")
        precondition(parseUpload("Vondu wants to upload my cv v2.pdf to jobs.example.co.in.")?.site == "jobs.example.co.in")
        precondition(parseUpload("Allow Vondu to upload this file using Browser?") == nil)
        precondition(parseSiteAccess("Allow Vondu to access truist.com?") == "truist.com")
        precondition(parseSiteAccess("Allow this browser task to access this sensitive site, on the web") == nil)
        print("selftest ok")
    }
}
#endif
