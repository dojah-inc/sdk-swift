import XCTest
@testable import DojahWidget

final class ExtraDataAndHomeCountryTests: XCTestCase {
    func testUserBioDataFillChecks() {
        XCTAssertFalse(UserBioData().isAllFilled())
        XCTAssertFalse(UserBioData().isAnyFilled())
        XCTAssertFalse(UserBioData(firstName: "Ada", lastName: "", dob: "01-01-1990").isAllFilled())
        XCTAssertTrue(UserBioData(firstName: "Ada", lastName: "Lovelace", dob: "01-01-1990").isAllFilled())
        XCTAssertTrue(UserBioData(firstName: "Ada").isAnyFilled())
        XCTAssertTrue(UserBioData(lastName: "Lovelace").isAnyFilled())
        XCTAssertTrue(UserBioData(dob: "01-01-1990").isAnyFilled())
        XCTAssertFalse(UserBioData(email: "a@b.com").isAnyFilled())
    }

    func testUserBioDataCodingKeys() {
        let data = UserBioData(firstName: "Ada", lastName: "Lovelace", dob: "01-01-1990", email: "a@b.com")
        XCTAssertEqual(data.dictionary["first_name"] as? String, "Ada")
        XCTAssertEqual(data.dictionary["last_name"] as? String, "Lovelace")
    }

    func testExtraGovDataIsFilled() {
        XCTAssertFalse(ExtraGovData().isFilled())
        XCTAssertFalse(ExtraGovData(bvn: "").isFilled())
        XCTAssertTrue(ExtraGovData(bvn: "222").isFilled())
        XCTAssertTrue(ExtraGovData(nin: "123").isFilled())
        XCTAssertTrue(ExtraGovData(vnin: "9").isFilled())
        XCTAssertTrue(ExtraGovData(dl: "A").isFilled())
    }

    func testExtraGovIdDataHelpers() {
        XCTAssertFalse(ExtraGovIdData().isAnyDataAvailable())
        XCTAssertEqual(ExtraGovIdData().getFirstData(), "")
        XCTAssertEqual(ExtraGovIdData().getNgIdType(), "")

        XCTAssertEqual(ExtraGovIdData(national: "NAT").getFirstData(), "NAT")
        XCTAssertEqual(ExtraGovIdData(national: "NAT").getNgIdType(), DJGovernmentIDType.ngNational.rawValue)
        XCTAssertEqual(ExtraGovIdData(passport: "PP").getFirstData(), "PP")
        XCTAssertEqual(ExtraGovIdData(passport: "PP").getNgIdType(), DJGovernmentIDType.ngPass.rawValue)
        XCTAssertEqual(ExtraGovIdData(dl: "DL").getFirstData(), "DL")
        XCTAssertEqual(ExtraGovIdData(dl: "DL").getNgIdType(), DJGovernmentIDType.ngDLI.rawValue)
        XCTAssertEqual(ExtraGovIdData(voter: "VC").getFirstData(), "VC")
        XCTAssertEqual(ExtraGovIdData(voter: "VC").getNgIdType(), DJGovernmentIDType.ngVotersCard.rawValue)
        XCTAssertEqual(ExtraGovIdData(nin: "NIN").getFirstData(), "NIN")
        XCTAssertEqual(ExtraGovIdData(nin: "NIN").getNgIdType(), DJGovernmentIDType.ngNINSlip.rawValue)
        XCTAssertEqual(ExtraGovIdData(others: "OTH").getFirstData(), "OTH")
        XCTAssertEqual(ExtraGovIdData(others: "OTH").getNgIdType(), "")
        XCTAssertTrue(ExtraGovIdData(others: "OTH").isAnyDataAvailable())
    }

    func testExtraLocationAndBusinessData() {
        XCTAssertFalse(ExtraLocationData().isParamSet())
        XCTAssertFalse(ExtraLocationData(longitude: "3").isParamSet())
        XCTAssertTrue(ExtraLocationData(longitude: "3", latitude: "6").isParamSet())
        XCTAssertFalse(ExtraBusinessData().isFilled())
        XCTAssertFalse(ExtraBusinessData(cac: "").isFilled())
        XCTAssertTrue(ExtraBusinessData(cac: "RC1").isFilled())
    }

    func testHomeCountryAndStateHelpers() {
        let country = TestFixtures.homeCountry()
        XCTAssertEqual(country.id, "NG")
        XCTAssertEqual(country.state(withCode: "LA")?.name, "Lagos")
        XCTAssertNil(country.state(withCode: "XX"))
        XCTAssertEqual(country.state(withName: "lagos")?.code, "LA")
        XCTAssertNil(country.state(withName: "Unknown"))
        XCTAssertEqual(country.stateNames, ["Lagos", "Abuja"])

        let lagos = country.states[0]
        XCTAssertTrue(lagos.hasSubdivisions)
        XCTAssertEqual(lagos.subdivisionCount, 3)
        XCTAssertTrue(lagos.hasSubdivision("ikeja"))
        XCTAssertFalse(lagos.hasSubdivision("Kano"))
        XCTAssertFalse(country.states[1].hasSubdivisions)
        XCTAssertEqual(country.states[1].id, "AB")
    }

    func testCustomQuestionsAnswerCodableAndEquality() throws {
        let answered = CustomQuestionsResult.AnsweredQuestion(
            text: "Color?",
            type: .single,
            options: ["Red", "Blue"],
            answer: .single("Red")
        )
        let encoded = try JSONEncoder().encode(answered)
        let decoded = try JSONDecoder().decode(CustomQuestionsResult.AnsweredQuestion.self, from: encoded)
        XCTAssertEqual(decoded.text, answered.text)
        XCTAssertEqual(decoded.type, answered.type)
        XCTAssertEqual(decoded.options, answered.options)
        XCTAssertEqual(decoded.answer, .text("Red"), "String answers decode as .text, not .single")

        XCTAssertEqual(
            CustomQuestionsResult.AnsweredQuestion.Answer.text("a"),
            CustomQuestionsResult.AnsweredQuestion.Answer.text("a")
        )
        XCTAssertNotEqual(
            CustomQuestionsResult.AnsweredQuestion.Answer.text("a"),
            CustomQuestionsResult.AnsweredQuestion.Answer.single("a")
        )
        XCTAssertEqual(
            CustomQuestionsResult.AnsweredQuestion.Answer.multiple(["a"]),
            CustomQuestionsResult.AnsweredQuestion.Answer.multiple(["a"])
        )

        let fromArray: CustomQuestionsResult.AnsweredQuestion = TestFixtures.decode(
            #"{"text":"Q","type":"multiple","options":["a","b"],"answer":["a"]}"#
        )
        XCTAssertEqual(fromArray.answer, .multiple(["a"]))

        XCTAssertThrowsError(
            try JSONDecoder().decode(
                CustomQuestionsResult.AnsweredQuestion.self,
                from: Data(#"{"text":"Q","type":"text","answer":{"bad":1}}"#.utf8)
            )
        )
    }

    func testDJCustomQuestionEventRequestDefaults() {
        let request = DJCustomQuestionEventRequest(value: [])
        XCTAssertEqual(request.name, "questions")
        XCTAssertEqual(request.services, [])
        XCTAssertEqual(request.dictionary["event_type"] as? String, "questions")
    }
}
