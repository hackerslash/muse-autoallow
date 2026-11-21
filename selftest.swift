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
        precondition(parseSiteAccess("Allow Vondu to access truist.com?") == "truist.com")
        precondition(parseSiteAccess("Allow this browser task to access this sensitive site, on the web") == nil)
        print("selftest ok")
    }
}
#endif
