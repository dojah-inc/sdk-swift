import XCTest
@testable import DojahWidget

final class BaseViewModelTests: XCTestCase {
    private var preference: MockPreference!
    private var events: MockEventsRemoteDatasource!
    private var decision: MockDecisionEngineRemoteDatasource!
    private var sut: BaseViewModel!

    override func setUp() {
        super.setUp()
        preference = MockPreference()
        events = MockEventsRemoteDatasource()
        decision = MockDecisionEngineRemoteDatasource()
        sut = BaseViewModel(
            eventsRemoteDatasource: events,
            decisionRemoteDatasource: decision,
            preference: preference
        )
    }

    func testGetNextStep() {
        preference.DJAuthStep = TestFixtures.authStep(name: .index, id: 0)
        preference.DJSteps = [
            TestFixtures.authStep(name: .index, id: 0),
            TestFixtures.authStep(name: .email, id: 1),
            TestFixtures.authStep(name: .userData, id: 2)
        ]
        XCTAssertEqual(sut.getNextStep()?.name, .email)
        XCTAssertEqual(sut.getNextStep(step: 2)?.name, .userData)
        XCTAssertNil(sut.getNextStep(step: 9))
    }

    func testGetNextStep_treatsNilIdAsZero() {
        preference.DJAuthStep = DJAuthStep(name: .index, id: nil, config: .init())
        preference.DJSteps = [TestFixtures.authStep(name: .email, id: 1)]
        XCTAssertEqual(sut.getNextStep()?.name, .email)
    }

    func testSetNextAuthStep_advancesAndNotifies() {
        var nextPageShown = false
        sut.showNextPage = { nextPageShown = true }
        preference.DJAuthStep = TestFixtures.authStep(name: .index, id: 0)
        preference.DJSteps = [
            TestFixtures.authStep(name: .index, id: 0),
            TestFixtures.authStep(name: .email, id: 1)
        ]

        sut.setNextAuthStep()
        XCTAssertEqual(preference.DJAuthStep.name, .email)
        XCTAssertTrue(nextPageShown)
    }

    func testSetNextAuthStep_canSkipShowingNextPage() {
        var nextPageShown = false
        sut.showNextPage = { nextPageShown = true }
        preference.DJAuthStep = TestFixtures.authStep(name: .index, id: 0)
        preference.DJSteps = [
            TestFixtures.authStep(name: .index, id: 0),
            TestFixtures.authStep(name: .email, id: 1)
        ]
        sut.setNextAuthStep(showNext: false)
        XCTAssertEqual(preference.DJAuthStep.name, .email)
        XCTAssertFalse(nextPageShown)
    }

    func testSetNextAuthStep_whenNoNextStepMakesDecision() {
        var loader: Bool?
        var message: FeedbackConfig?
        sut.showLoader = { loader = $0 }
        sut.showMessage = { message = $0 }
        preference.DJAuthStep = TestFixtures.authStep(name: .email, id: 9)
        preference.DJSteps = [TestFixtures.authStep(name: .email, id: 9)]
        decision.result = .success(EntityResponse(entity: DecisionResponse(status: .approved, reason: nil)))

        sut.setNextAuthStep()
        waitForRunAfter()

        XCTAssertTrue(decision.makeDecisionCalled)
        XCTAssertEqual(loader, false)
        XCTAssertEqual(preference.VerificationResultStatus, "approved")
        XCTAssertEqual(preference.DJAuthStep.name, .index)
        XCTAssertEqual(message?.feedbackType, .success)
        XCTAssertEqual(message?.titleText, "Verification successful")
    }

    func testSetNextAuthStep_decisionPendingAndFailed() {
        preference.DJSteps = []
        var message: FeedbackConfig?
        sut.showMessage = { message = $0 }

        decision.result = .success(EntityResponse(entity: DecisionResponse(status: .pending, reason: nil)))
        sut.setNextAuthStep()
        waitForRunAfter()
        XCTAssertEqual(message?.feedbackType, .warning)

        decision.result = .success(EntityResponse(entity: DecisionResponse(status: .failed, reason: nil)))
        sut.setNextAuthStep()
        waitForRunAfter()
        XCTAssertEqual(message?.feedbackType, .failure)
        XCTAssertEqual(preference.VerificationResultStatus, "failed")
    }

    func testSetNextAuthStep_decisionMissingStatusShowsReason() {
        preference.DJSteps = []
        var message: FeedbackConfig?
        sut.showMessage = { message = $0 }
        decision.result = .success(EntityResponse(entity: DecisionResponse(status: nil, reason: "manual review")))

        sut.setNextAuthStep()
        waitForRunAfter()
        XCTAssertEqual(message?.message, "manual review")
        XCTAssertEqual(message?.feedbackType, .failure)
    }

    func testSetNextAuthStep_decisionFailureShowsError() {
        preference.DJSteps = []
        var message: FeedbackConfig?
        sut.showMessage = { message = $0 }
        decision.result = .failure(.serverFailure)

        sut.setNextAuthStep()
        waitForRunAfter()
        XCTAssertEqual(message?.message, DJSDKError.serverFailure.uiMessage)
    }

    func testPostEvent_successAndFailureCallbacks() {
        var succeed = false
        var failed = false
        var loaderStates: [Bool] = []
        sut.showLoader = { loaderStates.append($0) }
        events.postEventResult = .success(TestFixtures.successResponse(success: true))

        sut.postEvent(request: .init(name: .emailCollected, value: "x"), didSucceed: { _ in succeed = true })
        XCTAssertTrue(succeed)
        XCTAssertEqual(loaderStates, [true, false])
        XCTAssertEqual(events.postedEvents.first?.name, .emailCollected)

        events.postEventResult = .success(TestFixtures.successResponse(success: false, msg: "nope"))
        var message: FeedbackConfig?
        sut.showMessage = { message = $0 }
        sut.postEvent(
            request: .init(name: .emailCollected, value: "x"),
            didFail: { _ in failed = true }
        )
        XCTAssertTrue(failed)
        XCTAssertEqual(message?.message, "nope")

        failed = false
        events.postEventResult = .failure(.tryAgain)
        sut.postEvent(
            request: .init(name: .emailCollected, value: "x"),
            showError: false,
            didFail: { error in
                failed = true
                XCTAssertEqual(error as? DJSDKError, .tryAgain)
            }
        )
        XCTAssertTrue(failed)
    }

    func testShowErrorMessageUsesDoneActionOrFallback() {
        var loaderHidden = false
        var customDone = false
        var fallbackDone = false
        sut.showLoader = { if $0 == false { loaderHidden = true } }
        sut.errorDoneAction = { fallbackDone = true }

        var config: FeedbackConfig?
        sut.showMessage = { config = $0 }
        sut.showErrorMessage("hello") {
            customDone = true
        }
        XCTAssertTrue(loaderHidden)
        XCTAssertEqual(config?.message, "hello")
        config?.doneAction?()
        XCTAssertTrue(customDone)
        XCTAssertFalse(fallbackDone)

        sut.showErrorMessage(DJSDKError.invalidOTPEntered)
        config?.doneAction?()
        XCTAssertTrue(fallbackDone)
        XCTAssertEqual(config?.message, DJSDKError.invalidOTPEntered.uiMessage)
    }
}
