#if SELFTEST
@main enum SelfTest {
    static func main() {
        let p = parseUpload("Vondu wants to upload mdafridisk_ai.pdf to coditude.keka.com. This task comes from the side chat")
        precondition(p?.file == "mdafridisk_ai.pdf" && p?.site == "coditude.keka.com")
        precondition(parseUpload("Vondu wants to upload my cv v2.pdf to jobs.example.co.in.")?.site == "jobs.example.co.in")
        precondition(parseUpload("Allow Vondu to upload this file using Browser?") == nil)
        precondition(parseUpload("Vondu wants to upload mdafridisk_backend.pdf to fa-euxc-saasfaprod1.fa.ocs.oraclecloud.com to apply for the Python Developer role in Mumbai, India.")?.site == "fa-euxc-saasfaprod1.fa.ocs.oraclecloud.com")
        precondition(parseUpload("Vondu wants to upload mdafridisk_backend.pdf to https://hczw.fa.us2.oraclecloud.com to apply for the Software Engineer role at CSC in Bangalore, India. This task comes from the side chat “Apply jobs using resume”. See details")?.site == "hczw.fa.us2.oraclecloud.com")
        precondition(parseUpload("Vondu wants to upload mdafridisk_backend.pdf to apply for the Software Engineer II role at Rippling via ats.rippling.com. This task comes from the side chat “x”. See details")?.site == "ats.rippling.com")
        precondition(parseUpload("Vondu wants to upload mdafridisk_backend.pdf to Rubrik to apply for the Software Engineer - Cloud Native Protection role in Bangalore, India (job 8327940). This task comes from the side chat “x”. See details")?.site == "Rubrik")
        let lq = parseUpload("Vondu wants to upload mdafridisk_backend.pdf to the Liquidity Services careers site to apply for the Engineer II, Software Dev. role in Chennai, India. This task comes from the side chat “x”. See details")
        precondition(lq?.file == "mdafridisk_backend.pdf" && lq?.site == "Liquidity Services careers site")
        precondition(parseUpload("Vondu wants to upload a file to careers.kula.ai. This task comes from the side chat “x”. See details")?.site == "careers.kula.ai")
        precondition(parseUpload("Vondu wants to upload a file to Rippling ATS. This task comes from the side chat “x”. See details")?.site == "Rippling ATS")
        let af = parseUpload("Vondu wants to upload a file to careers.kula.ai to apply for the SDE role via jobs.lever.co. This task comes from the side chat “x”. See details")
        precondition(af?.file == "a file" && af?.site == "careers.kula.ai")
        let cases: [(String, String?)] = [
            ("Allow Vondu to upload this file using Browser?", "upload"),
            ("Allow Vondu to access truist.com?", "web"),
            ("Allow Vondu to share information with api.notion.com?", "web"),
            ("Allow Vondu to share information with coloradowinefest.com for Morning Briefing?", "web"),
            ("Allow Vondu to read the web for Trip planner?", "web"),
            ("Allow Vondu to do some research for you?", "web"),
            ("Allow unrestricted web access for this task?", "web"),
            ("Allow Vondu unrestricted web access for Trip planner?", "web"),
            ("Allow Vondu to submit this form?", "browser"),
            ("Allow Vondu to select “Submit application” on jobs.lever.co?", "browser"),
            ("Allow Vondu to send an email in Gmail?", "connector"),
            ("Allow Vondu to post this message in Slack?", "connector"),
            ("Allow Vondu to use Linear?", "connector"),
            ("Allow Vondu to select “Place order” on shop.example.com?", nil),
            ("Allow Vondu to continue on this checkout page?", nil),
            ("Allow Vondu to complete this purchase?", nil),
            ("Allow Vondu to check out at allbirds.com?", nil),
            ("Allow Vondu to create this spend request?", nil),
            ("Allow Vondu to show content on Living room display?", nil),
            ("Are you sure you want to allow Muse to share this information with example.com?", nil),
            ("Allow Vondu to upload this file using Browser", nil),
            ("Allow once", nil),
        ]
        for (title, want) in cases { precondition(classify(title) == want, title) }
        precondition(promptAction("Allow Vondu to access truist.com?") == "access truist.com")
        precondition(promptAction("Allow unrestricted web access for this task?") == "unrestricted web access for this task")
        print("selftest ok")
    }
}
#endif
