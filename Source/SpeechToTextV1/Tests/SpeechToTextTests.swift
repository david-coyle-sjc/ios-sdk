/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import XCTest
import SpeechToTextV1

class SpeechToTextTests: XCTestCase {

    private var speechToText: SpeechToText!
    private let timeout: NSTimeInterval = 10.0

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
        instantiateSpeechToText()
    }
    
    /** Instantiate Speech to Text. */
    func instantiateSpeechToText() {
        let username = Credentials.SpeechToTextUsername
        let password = Credentials.SpeechToTextPassword
        speechToText = SpeechToText(username: username, password: password)
    }
    
    /** Fail false negatives. */
    func failWithError(error: NSError) {
        XCTFail("Positive test failed with error: \(error)")
    }
    
    /** Fail false positives. */
    func failWithResult<T>(result: T) {
        XCTFail("Negative test returned a result.")
    }
    
    /** Wait for expectations. */
    func waitForExpectations() {
        waitForExpectationsWithTimeout(timeout) { error in
            XCTAssertNil(error, "Timeout")
        }
    }
    
    // MARK: - Models
    
    func testModels() {
        let description1 = "Get information about all models."
        let expectation1 = expectationWithDescription(description1)
        
        var allModels = [Model]()
        speechToText.getModels(failWithError) { models in
            allModels = models
            expectation1.fulfill()
        }
        waitForExpectations()
        
        for model in allModels {
            let description2 = "Get information about a particular model."
            let expectation2 = expectationWithDescription(description2)
            speechToText.getModel(model.name) { newModel in
                XCTAssertEqual(model.name, newModel.name)
                XCTAssertEqual(model.rate, newModel.rate)
                XCTAssertEqual(model.language, newModel.language)
                XCTAssertEqual(model.url, newModel.url)
                XCTAssertEqual(model.description, newModel.description)
                expectation2.fulfill()
            }
            waitForExpectations()
        }
    }

    // MARK: - Transcribe File, Default Settings

    func testTranscribeFileDefaultWAV() {
        transcribeFileDefault("SpeechSample", withExtension: "wav", format: .WAV)
    }

    func testTranscribeFileDefaultOpus() {
        transcribeFileDefault("SpeechSample", withExtension: "ogg", format: .Opus)
    }

    func testTranscribeFileDefaultFLAC() {
        transcribeFileDefault("SpeechSample", withExtension: "flac", format: .FLAC)
    }

    func transcribeFileDefault(
        filename: String,
        withExtension: String,
        format: AudioMediaType)
    {
        let description = "Transcribe an audio file."
        let expectation = expectationWithDescription(description)

        let bundle = NSBundle(forClass: self.dynamicType)
        guard let file = bundle.URLForResource(filename, withExtension: withExtension) else {
            XCTFail("Unable to locate \(filename).\(withExtension).")
            return
        }

        let settings = RecognitionSettings(contentType: format)
        speechToText.recognize(file, settings: settings, failure: failWithError) { results in
            self.validateSTTResults(results.results, settings: settings)
            XCTAssertEqual(results.results.count, 1)
            XCTAssert(results.results.last?.final == true)
            let transcript = results.results.last?.alternatives.last?.transcript
            XCTAssertNotNil(transcript)
            XCTAssertGreaterThan(transcript!.characters.count, 0)
            expectation.fulfill()
        }
        waitForExpectations()
    }

    // MARK: - Transcribe File, Custom Settings

    func testTranscribeFileCustomWAV() {
        transcribeFileCustom("SpeechSample", withExtension: "wav", format: .WAV)
    }

    func testTranscribeFileCustomOpus() {
        transcribeFileCustom("SpeechSample", withExtension: "ogg", format: .Opus)
    }

    func testTranscribeFileCustomFLAC() {
        transcribeFileCustom("SpeechSample", withExtension: "flac", format: .FLAC)
    }

    func transcribeFileCustom(
        filename: String,
        withExtension: String,
        format: AudioMediaType)
    {
        let description = "Transcribe an audio file."
        let expectation = expectationWithDescription(description)

        let bundle = NSBundle(forClass: self.dynamicType)
        guard let file = bundle.URLForResource(filename, withExtension: withExtension) else {
            XCTFail("Unable to locate \(filename).\(withExtension).")
            return
        }

        var settings = RecognitionSettings(contentType: format)
        settings.continuous = true
        settings.inactivityTimeout = -1
        settings.keywords = ["tornadoes"]
        settings.keywordsThreshold = 0.75
        settings.maxAlternatives = 3
        settings.interimResults = true
        settings.wordAlternativesThreshold = 0.25
        settings.wordConfidence = true
        settings.timestamps = true
        settings.filterProfanity = false
        settings.smartFormatting = true

        speechToText.recognize(file, settings: settings, model: "en-US_BroadbandModel", learningOptOut: true, failure: failWithError) { results in
            self.validateSTTResults(results.results, settings: settings)
            if results.results.last?.final == true {
                let transcript = results.results.last?.alternatives.last?.transcript
                XCTAssertNotNil(transcript)
                XCTAssertGreaterThan(transcript!.characters.count, 0)
                expectation.fulfill()
            }
        }
        waitForExpectations()
    }

    // MARK: - Transcribe Data, Default Settings

    func testTranscribeDataDefaultWAV() {
        transcribeDataDefault("SpeechSample", withExtension: "wav", format: .WAV)
    }

    func testTranscribeDataDefaultOpus() {
        transcribeDataDefault("SpeechSample", withExtension: "ogg", format: .Opus)
    }

    func testTranscribeDataDefaultFLAC() {
        transcribeDataDefault("SpeechSample", withExtension: "flac", format: .FLAC)
    }

    func transcribeDataDefault(
        filename: String,
        withExtension: String,
        format: AudioMediaType)
    {
        let description = "Transcribe an audio file."
        let expectation = expectationWithDescription(description)

        let bundle = NSBundle(forClass: self.dynamicType)
        guard let file = bundle.URLForResource(filename, withExtension: withExtension) else {
            XCTFail("Unable to locate \(filename).\(withExtension).")
            return
        }

        guard let audio = NSData(contentsOfURL: file) else {
            XCTFail("Unable to read \(filename).\(withExtension).")
            return
        }

        let settings = RecognitionSettings(contentType: format)
        speechToText.recognize(audio, settings: settings, failure: failWithError) { results in
            self.validateSTTResults(results.results, settings: settings)
            XCTAssertEqual(results.results.count, 1)
            XCTAssert(results.results.last?.final == true)
            let transcript = results.results.last?.alternatives.last?.transcript
            XCTAssertNotNil(transcript)
            XCTAssertGreaterThan(transcript!.characters.count, 0)
            expectation.fulfill()
        }
        waitForExpectations()
    }

    // MARK: - Transcribe Data, Custom Settings

    func testTranscribeDataCustomWAV() {
        transcribeDataCustom("SpeechSample", withExtension: "wav", format: .WAV)
    }

    func testTranscribeDataCustomOpus() {
        transcribeDataCustom("SpeechSample", withExtension: "ogg", format: .Opus)
    }

    func testTranscribeDataCustomFLAC() {
        transcribeDataCustom("SpeechSample", withExtension: "flac", format: .FLAC)
    }

    func transcribeDataCustom(
        filename: String,
        withExtension: String,
        format: AudioMediaType)
    {
        let description = "Transcribe an audio file."
        let expectation = expectationWithDescription(description)

        let bundle = NSBundle(forClass: self.dynamicType)
        guard let file = bundle.URLForResource(filename, withExtension: withExtension) else {
            XCTFail("Unable to locate \(filename).\(withExtension).")
            return
        }

        guard let audio = NSData(contentsOfURL: file) else {
            XCTFail("Unable to read \(filename).\(withExtension).")
            return
        }

        var settings = RecognitionSettings(contentType: format)
        settings.continuous = true
        settings.inactivityTimeout = -1
        settings.keywords = ["tornadoes"]
        settings.keywordsThreshold = 0.75
        settings.maxAlternatives = 3
        settings.interimResults = true
        settings.wordAlternativesThreshold = 0.25
        settings.wordConfidence = true
        settings.timestamps = true
        settings.filterProfanity = false
        settings.smartFormatting = true

        speechToText.recognize(audio, settings: settings, model: "en-US_BroadbandModel", learningOptOut: true, failure: failWithError) { results in
            self.validateSTTResults(results.results, settings: settings)
            if results.results.last?.final == true {
                let transcript = results.results.last?.alternatives.last?.transcript
                XCTAssertNotNil(transcript)
                XCTAssertGreaterThan(transcript!.characters.count, 0)
                expectation.fulfill()
            }
        }
        waitForExpectations()
    }
    
    // MARK: - Transcribe Data with Smart Formatting
    
    func testTranscribeStockAnnouncementCustomWAV() {
        transcribeDataCustomForNumbers("StockAnnouncement", withExtension: "wav", format: .WAV, substring: "$152.37")
    }
    
    func transcribeDataCustomForNumbers(
        filename: String,
        withExtension: String,
        format: AudioMediaType,
        substring: String)
    {
        let description = "Transcribe an audio file with smart formatting."
        let expectation = expectationWithDescription(description)
        
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let file = bundle.URLForResource(filename, withExtension: withExtension) else {
            XCTFail("Unable to locate \(filename).\(withExtension).")
            return
        }
        
        guard let audio = NSData(contentsOfURL: file) else {
            XCTFail("Unable to read \(filename).\(withExtension).")
            return
        }
        
        var settings = RecognitionSettings(contentType: format)
        settings.smartFormatting = true
        
        speechToText.recognize(audio, settings: settings, model: "en-US_BroadbandModel", learningOptOut: true, failure: failWithError) { results in
            self.validateSTTResults(results.results, settings: settings)
            if results.results.last?.final == true {
                let transcript = results.results.last?.alternatives.last?.transcript
                XCTAssertNotNil(transcript)
                XCTAssertGreaterThan(transcript!.characters.count, 0)
                XCTAssertTrue(transcript!.containsString(substring))
                expectation.fulfill()
            }
        }
        waitForExpectations()
    }

    // MARK: - Transcribe Streaming

    func testTranscribeStreaming() {
        print("")
        print("******************************************************************************")
        print(" WARNING: Cannot test streaming audio in simulator.")
        print(" No audio capture devices are available. Please manually load the test")
        print(" application for streaming audio and run it on a physical device.")
        print("******************************************************************************")
        print("")
    }

    // MARK: - Validation Functions

    func validateSTTResults(results: [SpeechRecognitionResult], settings: RecognitionSettings) {
        for result in results {
            validateSTTResult(result, settings: settings)
        }
    }

    func validateSTTResult(result: SpeechRecognitionResult, settings: RecognitionSettings) {

        XCTAssertNotNil(result.final)
        let final = result.final

        XCTAssertNotNil(result.alternatives)
        var alternativesWithConfidence = 0
        for alternative in result.alternatives {
            if alternative.confidence != nil {
                alternativesWithConfidence += 1
                validateSTTTranscription(alternative, best: true, final: final, settings: settings)
            } else {
                validateSTTTranscription(alternative, best: false, final: final, settings: settings)
            }
        }

        if final {
            XCTAssertEqual(alternativesWithConfidence, 1)
        }

        if settings.keywords?.count > 0 && final {
            XCTAssertNotNil(settings.keywordsThreshold)
            XCTAssertGreaterThanOrEqual(settings.keywordsThreshold!, 0.0)
            XCTAssertLessThanOrEqual(settings.keywordsThreshold!, 1.0)
            XCTAssertNotNil(result.keywordResults)
            XCTAssertGreaterThan(result.keywordResults!.count, 0)
            for (keyword, keywordResults) in result.keywordResults! {
                validateSTTKeywordResults(keyword, keywordResults: keywordResults)
            }
        } else {
            let isEmpty = (result.keywordResults?.count == 0)
            let isNil = (result.keywordResults == nil)
            XCTAssert(isEmpty || isNil)
        }

        if settings.wordAlternativesThreshold != nil && final {
            XCTAssertNotNil(settings.wordAlternativesThreshold)
            XCTAssertGreaterThanOrEqual(settings.wordAlternativesThreshold!, 0.0)
            XCTAssertLessThanOrEqual(settings.wordAlternativesThreshold!, 1.0)
            XCTAssertNotNil(result.wordAlternatives)
            XCTAssertGreaterThan(result.wordAlternatives!.count, 0)
            for wordAlternatives in result.wordAlternatives! {
                validateSTTWordAlternativeResults(wordAlternatives)
            }
        } else {
            let isEmpty = (result.wordAlternatives?.count == 0)
            let isNil = (result.keywordResults == nil)
            XCTAssert(isEmpty || isNil)
        }
    }

    func validateSTTTranscription(
        transcription: SpeechRecognitionAlternative,
        best: Bool,
        final: Bool,
        settings: RecognitionSettings)
    {
        XCTAssertNotNil(transcription.transcript)
        XCTAssertGreaterThan(transcription.transcript.characters.count, 0)

        if best && final {
            XCTAssertNotNil(transcription.confidence)
            XCTAssertGreaterThanOrEqual(transcription.confidence!, 0.0)
            XCTAssertLessThanOrEqual(transcription.confidence!, 1.0)
        } else {
            XCTAssertNil(transcription.confidence)
        }

        if settings.timestamps == true && (!final || best) {
            XCTAssertNotNil(transcription.timestamps)
            XCTAssertGreaterThan(transcription.timestamps!.count, 0)
            for timestamp in transcription.timestamps! {
                validateSTTWordTimestamp(timestamp)
            }
        } else {
            let isEmpty = (transcription.timestamps?.count == 0)
            let isNil = (transcription.timestamps == nil)
            XCTAssert(isEmpty || isNil)
        }

        if settings.wordConfidence == true && final && best {
            XCTAssertNotNil(transcription.wordConfidence)
            XCTAssertGreaterThan(transcription.wordConfidence!.count, 0)
            for word in transcription.wordConfidence! {
                validateSTTWordConfidence(word)
            }
        } else {
            let isEmpty = (transcription.wordConfidence?.count == 0)
            let isNil = (transcription.wordConfidence == nil)
            XCTAssert(isEmpty || isNil)
        }
    }

    func validateSTTWordTimestamp(timestamp: WordTimestamp) {
        XCTAssertGreaterThan(timestamp.word.characters.count, 0)
        XCTAssertGreaterThanOrEqual(timestamp.startTime, 0.0)
        XCTAssertGreaterThanOrEqual(timestamp.endTime, timestamp.startTime)
    }

    func validateSTTWordConfidence(word: WordConfidence) {
        XCTAssertGreaterThan(word.word.characters.count, 0)
        XCTAssertGreaterThanOrEqual(word.confidence, 0.0)
        XCTAssertLessThanOrEqual(word.confidence, 1.0)
    }

    func validateSTTKeywordResults(keyword: String, keywordResults: [KeywordResult]) {
        XCTAssertGreaterThan(keyword.characters.count, 0)
        XCTAssertGreaterThan(keywordResults.count, 0)
        for keywordResult in keywordResults {
            validateSTTKeywordResult(keywordResult)
        }
    }

    func validateSTTKeywordResult(keywordResult: KeywordResult) {
        XCTAssertGreaterThan(keywordResult.normalizedText.characters.count, 0)
        XCTAssertGreaterThanOrEqual(keywordResult.startTime, 0)
        XCTAssertGreaterThanOrEqual(keywordResult.endTime, keywordResult.startTime)
        XCTAssertGreaterThanOrEqual(keywordResult.confidence, 0.0)
        XCTAssertLessThanOrEqual(keywordResult.confidence, 1.0)
    }

    func validateSTTWordAlternativeResults(wordAlternatives: WordAlternativeResults) {
        XCTAssertGreaterThanOrEqual(wordAlternatives.startTime, 0.0)
        XCTAssertGreaterThanOrEqual(wordAlternatives.endTime, wordAlternatives.startTime)
        XCTAssertGreaterThan(wordAlternatives.alternatives.count, 0)
        for wordAlternative in wordAlternatives.alternatives {
            validateSTTWordAlternativeResult(wordAlternative)
        }
    }

    func validateSTTWordAlternativeResult(wordAlternative: WordAlternativeResult) {
        XCTAssertGreaterThanOrEqual(wordAlternative.confidence, 0.0)
        XCTAssertLessThanOrEqual(wordAlternative.confidence, 1.0)
        XCTAssertGreaterThan(wordAlternative.word.characters.count, 0)
    }
}
