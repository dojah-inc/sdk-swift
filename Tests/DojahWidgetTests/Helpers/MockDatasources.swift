import Foundation
@testable import DojahWidget

final class MockEventsRemoteDatasource: EventsRemoteDatasourceProtocol {
    var postedEvents: [DJEventRequest] = []
    var postedCustomQuestions: [DJCustomQuestionEventRequest] = []
    var postedEmailEvents: [DJEventRequest] = []

    var postEventResult: DJResult<SuccessEntityResponse> = .success(TestFixtures.successResponse())
    var postEmailResult: DJResult<EntityResponse<EmailCollectedEventResponse>> = .success(
        EntityResponse(entity: EmailCollectedEventResponse(
            success: true,
            continueVerification: false,
            duplicateReference: false,
            data: nil,
            msg: "ok",
            message: nil
        ))
    )
    var postCustomQuestionsResult: DJResult<SuccessEntityResponse> = .success(TestFixtures.successResponse())

    func postEvent(request: DJEventRequest, completion: @escaping DJResultAction<SuccessEntityResponse>) {
        postedEvents.append(request)
        completion(postEventResult)
    }

    func postEmailCollectedEvent(
        request: DJEventRequest,
        completion: @escaping DJResultAction<EntityResponse<EmailCollectedEventResponse>>
    ) {
        postedEmailEvents.append(request)
        completion(postEmailResult)
    }

    func postCustomQuestionsEvent(
        request: DJCustomQuestionEventRequest,
        completion: @escaping DJResultAction<SuccessEntityResponse>
    ) {
        postedCustomQuestions.append(request)
        completion(postCustomQuestionsResult)
    }
}

final class MockDecisionEngineRemoteDatasource: DecisionEngineRemoteDatasourceProtocol {
    var makeDecisionCalled = false
    var result: DJResult<EntityResponse<DecisionResponse>> = .success(
        EntityResponse(entity: DecisionResponse(status: .approved, reason: nil))
    )

    func makeVerificationDecision(completion: @escaping DJResultAction<EntityResponse<DecisionResponse>>) {
        makeDecisionCalled = true
        completion(result)
    }
}

final class MockCountriesLocalDatasource: CountriesLocalDatasourceProtocol {
    var storedCountries: [DJCountryDB]
    var saveCalled = false
    var lastSaved: [DJCountryDB] = []

    init(countries: [DJCountryDB] = [TestFixtures.country()]) {
        self.storedCountries = countries
    }

    func saveCountries(_ countries: [DJCountryDB]) throws {
        saveCalled = true
        lastSaved = countries
        storedCountries = countries
    }

    func getCountries() -> [DJCountryDB] {
        storedCountries
    }

    func getCountry(iso2: String) -> DJCountryDB? {
        storedCountries.first { $0.iso2.insensitiveEquals(iso2) }
    }

    func getCountryByName(_ name: String) -> DJCountryDB? {
        storedCountries.first { $0.countryName.insensitiveEquals(name) }
    }
}

final class MockOTPRemoteDatasource: OTPRemoteDatasourceProtocol {
    var requestParams: DJParameters?
    var validateParams: DJParameters?
    var requestResult: DJResult<EntityResponse<[OTPRequestResponse]>> = .success(
        EntityResponse(entity: [
            OTPRequestResponse(referenceID: "ref-1", destination: "0803", statusID: "1", status: "sent")
        ])
    )
    var validateResult: DJResult<EntityResponse<OTPValidationResponse>> = .success(
        EntityResponse(entity: OTPValidationResponse(valid: true))
    )

    func requestOTP(
        params: DJParameters,
        completion: @escaping DJResultAction<EntityResponse<[OTPRequestResponse]>>
    ) {
        requestParams = params
        completion(requestResult)
    }

    func validateOTP(
        params: DJParameters,
        completion: @escaping DJResultAction<EntityResponse<OTPValidationResponse>>
    ) {
        validateParams = params
        completion(validateResult)
    }
}

final class MockUserDataRemoteDatasource: UserDataRemoteDatasourceProtocol {
    var lastParams: DJParameters?
    var result: DJResult<SuccessEntityResponse> = .success(TestFixtures.successResponse())

    func saveUserData(params: DJParameters, completion: @escaping DJResultAction<SuccessEntityResponse>) {
        lastParams = params
        completion(result)
    }
}

final class MockBusinessDataRemoteDatasource: BusinessDataRemoteDatasourceProtocol {
    var lastType: BusinessDataType?
    var lastParams: DJParameters?
    var result: DJResult<EntityResponse<BusinessDataResponse>> = .success(
        EntityResponse(entity: BusinessDataResponse(
            companyName: "Dojah",
            rcNumber: "123",
            dateOfRegistration: nil,
            address: nil,
            typeOfCompany: nil,
            business: "FINTECH",
            status: "ACTIVE"
        ))
    )

    func verify(
        type: BusinessDataType,
        params: DJParameters,
        completion: @escaping DJResultAction<EntityResponse<BusinessDataResponse>>
    ) {
        lastType = type
        lastParams = params
        completion(result)
    }
}

final class MockGovernmentDataRemoteDatasource: GovernmentDataRemoteDatasourceProtocol {
    var lastNumber: String?
    var lastIDType: DJGovernmentIDType?
    var result: DJResult<EntityResponse<GovernmentDataLookupEntity>> = .success(
        EntityResponse(entity: TestFixtures.lookupEntity())
    )

    func lookupID(
        number: String,
        idType: DJGovernmentIDType,
        completion: @escaping DJResultAction<EntityResponse<GovernmentDataLookupEntity>>
    ) {
        lastNumber = number
        lastIDType = idType
        completion(result)
    }
}

final class MockLivenessRemoteDatasource: LivenessRemoteDatasourceProtocol {
    var analysisParams: DJParameters?
    var checkParams: DJParameters?
    var verifyParams: DJParameters?
    var uploadParams: DJParameters?

    var analysisResult: DJResult<EntityResponse<ImageAnalysisResponse>> = .success(
        EntityResponse(entity: ImageAnalysisResponse(face: nil, id: nil))
    )
    var checkResult: DJResult<EntityResponse<ImageCheckResponse>> = .success(
        EntityResponse(entity: ImageCheckResponse(match: true, reason: nil, continueVerification: false))
    )
    var verifyResult: DJResult<EntityResponse<ImageVerificationResponse>> = .success(
        EntityResponse(entity: ImageVerificationResponse(
            person: nil, id: nil, overall: nil, business: nil, device: nil, ip: nil, referenceID: nil
        ))
    )
    var uploadResult: DJResult<SuccessEntityResponse> = .success(TestFixtures.successResponse())

    func performImageAnalysis(
        params: DJParameters,
        completion: @escaping DJResultAction<EntityResponse<ImageAnalysisResponse>>
    ) {
        analysisParams = params
        completion(analysisResult)
    }

    func performImageCheck(
        params: DJParameters,
        completion: @escaping DJResultAction<EntityResponse<ImageCheckResponse>>
    ) {
        checkParams = params
        completion(checkResult)
    }

    func verifyImage(
        params: DJParameters,
        completion: @escaping DJResultAction<EntityResponse<ImageVerificationResponse>>
    ) {
        verifyParams = params
        completion(verifyResult)
    }

    func uploadDocument(
        params: DJParameters,
        completion: @escaping DJResultAction<SuccessEntityResponse>
    ) {
        uploadParams = params
        completion(uploadResult)
    }
}

final class MockAddressVerificationRemoteDatasource: AddressVerificationRemoteDatasourceProtocol {
    var lastType: AddressType?
    var lastParams: DJParameters?
    var result: DJResult<SuccessEntityResponse> = .success(TestFixtures.successResponse())

    func sendAddress(
        type: AddressType,
        params: DJParameters,
        completion: @escaping DJResultAction<SuccessEntityResponse>
    ) {
        lastType = type
        lastParams = params
        completion(result)
    }
}

final class MockAuthenticationRemoteDatasource: AuthenticationRemoteDatasourceProtocol {
    var preAuthParams: DJParameters?
    var authParams: DJParameters?
    var saveIPParams: DJParameters?

    var preAuthResult: DJResult<DJPreAuthResponse> = .failure(.tryAgain)
    var authResult: DJResult<DJAuthResponse> = .failure(.tryAgain)
    var ipResult: DJResult<DJIPAddress> = .success(DJIPAddress(ip: "1.1.1.1"))
    var saveIPResult: DJResult<DJIPAddressResponse> = .success(
        DJIPAddressResponse(entity: nil)
    )

    func getPreAuthenticationInfo(params: DJParameters, completion: @escaping DJResultAction<DJPreAuthResponse>) {
        preAuthParams = params
        completion(preAuthResult)
    }

    func authenticate(params: DJParameters, completion: @escaping DJResultAction<DJAuthResponse>) {
        authParams = params
        completion(authResult)
    }

    func getIPAddress(completion: @escaping DJResultAction<DJIPAddress>) {
        completion(ipResult)
    }

    func saveIPAddress(params: DJParameters, completion: @escaping DJResultAction<DJIPAddressResponse>) {
        saveIPParams = params
        completion(saveIPResult)
    }
}

final class MockMetaDataRemoteDatasource: MetaDataRemoteDatasourceProtocol {
    var lastParams: DJParameters?
    var result: DJResult<SuccessEntityResponse> = .success(TestFixtures.successResponse())

    func sendMetaData(params: DJParameters, completion: @escaping DJResultAction<SuccessEntityResponse>) {
        lastParams = params
        completion(result)
    }
}

final class MockNetworkService: NetworkServiceProtocol {
    var lastMethod: DJHttpMethod?
    var lastPath: DJRemotePath?
    var lastParameters: DJParameters?
    var lastHeaders: DJHeaderParameters?
    var requestCount = 0

    var handler: ((Any.Type) -> Any)?

    func makeRequest<T: Codable>(
        responseType: T.Type,
        requestMethod: DJHttpMethod,
        remotePath: DJRemotePath,
        parameters: DJParameters?,
        headers: DJHeaderParameters?,
        completion: @escaping DJResultAction<T>
    ) {
        requestCount += 1
        lastMethod = requestMethod
        lastPath = remotePath
        lastParameters = parameters
        lastHeaders = headers
        if let handler, let result = handler(T.self) as? DJResult<T> {
            completion(result)
        }
    }
}

final class MockInputValidator: IInputValidator {
    var emailResult = ValidationMessage(isValid: true, message: "", validationType: .email)
    var emailOrPhoneResult = ValidationMessage(isValid: true, message: "", validationType: .emailOrPhone)
    var phoneResult = ValidationMessage(isValid: true, message: "", validationType: .phoneNumber)
    var nameResult = ValidationMessage(isValid: true, message: "", validationType: .name)
    var addressResult = ValidationMessage(isValid: true, message: "", validationType: .address)
    var passwordResult = ValidationMessage(isValid: true, message: "", validationType: .password)
    var confirmPasswordResult = ValidationMessage(isValid: true, message: "", validationType: .confirmPassword)
    var amountResult = ValidationMessage(isValid: true, message: "", validationType: .amount)
    var dobResult = ValidationMessage(isValid: true, message: "", validationType: .dob)
    var alphaNumericResult = ValidationMessage(isValid: true, message: "", validationType: .alphaNumeric)
    var genericResult = ValidationMessage(isValid: true, message: "", validationType: .email)

    var lastValidatedValue: String?
    var lastValidatedType: ValidationType?

    func validateEmailAddress(_ email: String) -> ValidationMessage { emailResult }
    func validateEmailOrPhone(_ emailOrPhone: String) -> ValidationMessage { emailOrPhoneResult }
    func validatePhoneNumber(_ phoneNo: String) -> ValidationMessage { phoneResult }
    func validateName(_ name: String) -> ValidationMessage { nameResult }
    func validateAddress(_ address: String) -> ValidationMessage { addressResult }
    func validatePassword(_ password: String) -> ValidationMessage { passwordResult }
    func validateConfirmPassword(_ password: String, _ confirmPassword: String) -> ValidationMessage { confirmPasswordResult }
    func validateAmount(_ amount: String) -> ValidationMessage { amountResult }
    func validateDOB(_ dob: String) -> ValidationMessage { dobResult }
    func validateAlphaNumeric(_ text: String) -> ValidationMessage { alphaNumericResult }

    func validate(_ value: String, for type: ValidationType) -> ValidationMessage {
        lastValidatedValue = value
        lastValidatedType = type
        return genericResult
    }
}
