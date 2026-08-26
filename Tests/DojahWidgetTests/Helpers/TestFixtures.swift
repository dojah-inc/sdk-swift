import Foundation
import UIKit
@testable import DojahWidget

enum TestFixtures {
    static func governmentID(
        name: String? = "BVN",
        abbr: String? = "BVN",
        subtext: String? = nil,
        subtext2: String? = nil,
        placeholder: String? = "Enter BVN",
        idEnum: String? = "BVN",
        spanid: String? = nil,
        inputType: DJInputMode? = .numeric,
        inputMode: DJInputMode? = .numeric,
        minLength: String? = "11",
        maxLength: String? = "11",
        id: String? = "1",
        value: String? = "BVN",
        idName: String? = "Bank Verification Number"
    ) -> DJGovernmentID {
        DJGovernmentID(
            name: name,
            abbr: abbr,
            subtext: subtext,
            subtext2: subtext2,
            placeholder: placeholder,
            idEnum: idEnum,
            spanid: spanid,
            inputType: inputType,
            inputMode: inputMode,
            minLength: minLength,
            maxLength: maxLength,
            id: id,
            value: value,
            idName: idName
        )
    }

    static func governmentIDConfig(
        bvn: DJGovernmentID? = nil,
        nin: DJGovernmentID? = nil,
        vnin: DJGovernmentID? = nil,
        dl: DJGovernmentID? = nil,
        passport: DJGovernmentID? = nil,
        national: DJGovernmentID? = nil,
        permit: DJGovernmentID? = nil,
        custom: DJGovernmentID? = nil,
        voter: DJGovernmentID? = nil,
        mobile: DJGovernmentID? = nil,
        ngDLI: DJGovernmentID? = nil,
        ngPass: DJGovernmentID? = nil,
        ngNat: DJGovernmentID? = nil,
        ukRP: DJGovernmentID? = nil,
        ngCustom: DJGovernmentID? = nil,
        ngVcard: DJGovernmentID? = nil,
        ngNINSlip: DJGovernmentID? = nil,
        selfie: DJGovernmentID? = nil,
        selfieVideo: DJGovernmentID? = nil,
        otp: DJGovernmentID? = nil,
        whatsappOtp: DJGovernmentID? = nil,
        ghDL: DJGovernmentID? = nil,
        ghVoter: DJGovernmentID? = nil,
        tzNIN: DJGovernmentID? = nil,
        ugID: DJGovernmentID? = nil,
        ugTelco: DJGovernmentID? = nil,
        keDL: DJGovernmentID? = nil,
        keID: DJGovernmentID? = nil,
        keKRA: DJGovernmentID? = nil,
        saDL: DJGovernmentID? = nil,
        saID: DJGovernmentID? = nil,
        cac: DJGovernmentID? = nil,
        tin: DJGovernmentID? = nil
    ) -> DJGovernmentIDConfig {
        DJGovernmentIDConfig(
            bvn: bvn,
            nin: nin,
            vnin: vnin,
            dl: dl,
            passport: passport,
            national: national,
            permit: permit,
            custom: custom,
            voter: voter,
            mobile: mobile,
            ngDLI: ngDLI,
            ngPass: ngPass,
            ngNat: ngNat,
            ukRP: ukRP,
            ngCustom: ngCustom,
            ngVcard: ngVcard,
            ngNINSlip: ngNINSlip,
            selfie: selfie,
            selfieVideo: selfieVideo,
            otp: otp,
            whatsappOtp: whatsappOtp,
            ghDL: ghDL,
            ghVoter: ghVoter,
            tzNIN: tzNIN,
            ugID: ugID,
            ugTelco: ugTelco,
            keDL: keDL,
            keID: keID,
            keKRA: keKRA,
            saDL: saDL,
            saID: saID,
            cac: cac,
            tin: tin
        )
    }

    static func country(
        iso2: String = "NG",
        countryName: String = "Nigeria",
        iso3: String = "NGA",
        phoneCode: String = "234"
    ) -> DJCountryDB {
        DJCountryDB(
            iso2: iso2,
            countryName: countryName,
            iso3: iso3,
            topLevelDomain: ".ng",
            fips: "NI",
            isoNumeric: "566",
            geoNameID: "2328926",
            e164: 234,
            phoneCode: phoneCode,
            continent: "Africa",
            capital: "Abuja",
            timeZoneInCapital: "Africa/Lagos",
            currency: "NGN",
            languageCodes: "en",
            languages: "English",
            areaKM2: 923768,
            internetHosts: "1",
            internetUsers: "1",
            phonesMobile: "1",
            phonesLandline: "1",
            gdp: "1"
        )
    }

    static func page(
        name: DJPageName,
        config: DJPageConfig? = DJPageConfig()
    ) -> DJPage {
        DJPage(pageName: name, config: config)
    }

    static func authStep(
        name: DJPageName = .index,
        id: Int = 0,
        config: DJPageConfig? = DJPageConfig(),
        sessionID: String? = nil,
        status: DJAuthStepStatus? = .pending
    ) -> DJAuthStep {
        DJAuthStep(name: name, id: id, config: config, sessionID: sessionID, status: status)
    }

    static func pricingDataConfig(
        bvn: String? = "bvn-svc",
        bvnAdvance: String? = "bvn-adv-svc",
        vnin: String? = "vnin-svc",
        nin: String? = "nin-svc",
        dl: String? = "dl-svc",
        mobile: String? = "mobile-svc",
        ghDL: String? = "gh-dl-svc",
        ghVoter: String? = "gh-voter-svc",
        keKra: String? = "ke-kra-svc",
        keID: String? = "ke-id-svc",
        keDL: String? = "ke-dl-svc",
        aoNin: String? = "ao-nin-svc",
        zaID: String? = "za-id-svc",
        verification: String? = "verification-svc",
        aml: String? = "aml-svc",
        cac: String? = "cac-svc",
        idDefault: String? = "id-default-svc",
        selfie: String? = "selfie-svc",
        video: String? = "video-svc",
        otp: String? = "otp-svc",
        whatsappOtp: String? = "whatsapp-svc",
        emailOtp: String? = "email-otp-svc"
    ) -> PricingDataConfig {
        PricingDataConfig(
            bvn: bvn,
            bvnAdvance: bvnAdvance,
            vnin: vnin,
            nin: nin,
            dl: dl,
            mobile: mobile,
            ghDL: ghDL,
            ghVoter: ghVoter,
            keKra: keKra,
            keID: keID,
            keDL: keDL,
            aoNin: aoNin,
            zaID: zaID,
            verification: verification,
            aml: aml,
            cac: cac,
            idDefault: idDefault,
            selfie: selfie,
            video: video,
            otp: otp,
            whatsappOtp: whatsappOtp,
            emailOtp: emailOtp
        )
    }

    static func pricingServicesConfig() -> PricingServicesConfig {
        let data = pricingDataConfig()
        return PricingServicesConfig(
            aml: data,
            governmentData: data,
            governmentDataVerification: data,
            selfie: data,
            businessData: data,
            phoneNumber: data,
            address: data,
            email: data,
            businessID: data,
            id: data,
            index: data,
            countries: data,
            additionalDocument: data,
            signature: data
        )
    }

    static func successResponse(success: Bool = true, msg: String? = "ok") -> SuccessEntityResponse {
        EntityResponse(entity: DJSuccessMessageEntity(success: success, msg: msg))
    }

    static func lookupEntity(
        customerID: String? = "cust-1",
        firstName: String? = "Ada",
        lastName: String? = "Lovelace",
        middleName: String? = "King",
        dateOfBirth: String? = "10-12-1815",
        phoneNumber1: String? = "08012345678",
        phoneNumber2: String? = nil,
        image: String? = "base64-image",
        photo: String? = nil,
        firstname: String? = nil,
        middlename: String? = nil,
        phoneNumberMiddleName: String? = nil
    ) -> GovernmentDataLookupEntity {
        decode(
            """
            {
                "customer": \(jsonString(customerID)),
                "first_name": \(jsonString(firstName)),
                "last_name": \(jsonString(lastName)),
                "middle_name": \(jsonString(middleName)),
                "date_of_birth": \(jsonString(dateOfBirth)),
                "phone_number1": \(jsonString(phoneNumber1)),
                "phone_number2": \(jsonString(phoneNumber2)),
                "image": \(jsonString(image)),
                "photo": \(jsonString(photo)),
                "firstname": \(jsonString(firstname)),
                "middlename": \(jsonString(middlename)),
                "MiddleName": \(jsonString(phoneNumberMiddleName))
            }
            """
        )
    }

    static func homeCountry(
        code2: String = "NG",
        states: [State] = [
            State(code: "LA", name: "Lagos", subdivision: ["Ikeja", "Lekki", "Surulere"]),
            State(code: "AB", name: "Abuja", subdivision: [])
        ]
    ) -> HomeCountry {
        HomeCountry(
            code2: code2,
            code3: "NGA",
            name: "Nigeria",
            capital: "Abuja",
            region: "Africa",
            subregion: "Western Africa",
            states: states
        )
    }

    static func decode<T: Decodable>(_ json: String) -> T {
        try! JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    private static func jsonString(_ value: String?) -> String {
        guard let value else { return "null" }
        return "\"\(value)\""
    }
}
