import XCTest
import Combine
@testable import VoiceReminders

final class ReminderFormViewModelTests: XCTestCase {
    var viewModel: ReminderFormViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = ReminderFormViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertEqual(viewModel.priority, 1)
        XCTAssertFalse(viewModel.isValid)
        XCTAssertTrue(viewModel.fieldErrors.value.isEmpty)
    }
    
    // MARK: - Title Validation Tests
    
    func testTitleValidation_WhenEmpty() {
        // When
        viewModel.title = ""
        
        // Then
        let expectation = expectation(description: "Title validation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.viewModel.isValid)
            XCTAssertEqual(self.viewModel.fieldErrors.value["title"], "Reminder title is required")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTitleValidation_WhenTooShort() {
        // When
        viewModel.title = "ab"
        
        // Then
        let expectation = expectation(description: "Title validation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.viewModel.isValid)
            XCTAssertEqual(self.viewModel.fieldErrors.value["title"], "Title must be at least 3 characters")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTitleValidation_WhenValid() {
        // When
        viewModel.title = "Valid Title"
        
        // Then
        let expectation = expectation(description: "Title validation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNil(self.viewModel.fieldErrors.value["title"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Notes Validation Tests
    
    func testNotesValidation_WhenEmpty() {
        // When
        viewModel.notes = ""
        
        // Then
        let expectation = expectation(description: "Notes validation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNil(self.viewModel.fieldErrors.value["notes"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testNotesValidation_WhenTooShort() {
        // When
        viewModel.notes = "note"
        
        // Then
        let expectation = expectation(description: "Notes validation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.fieldErrors.value["notes"], "Notes must be at least 5 characters if provided")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testNotesValidation_WhenValid() {
        // When
        viewModel.notes = "Valid notes content"
        
        // Then
        let expectation = expectation(description: "Notes validation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNil(self.viewModel.fieldErrors.value["notes"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Form Submission Tests
    
    func testSubmitForm_WhenInvalid() async {
        // Given
        viewModel.title = ""
        
        // When/Then
        do {
            try await viewModel.submitForm()
            XCTFail("Form submission should fail with invalid fields")
        } catch ValidationError.invalidField {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSubmitForm_WhenValid() async {
        // Given
        viewModel.title = "Valid Title"
        viewModel.notes = "Valid notes content"
        
        // When/Then
        do {
            try await viewModel.submitForm()
            // Note: Currently, submitForm() is not implemented, so we can't test the actual submission
            // When implementing the actual submission logic, add appropriate assertions here
        } catch {
            XCTFail("Form submission should succeed with valid fields: \(error)")
        }
    }
    
    // MARK: - Field Subscription Tests
    
    func testFieldSubscriptions_UpdateValidationState() {
        // Given
        let validationStateExpectation = expectation(description: "Validation state updates")
        var validationStates: [Bool] = []
        
        viewModel.validationState
            .sink { state in
                validationStates.append(state)
                if validationStates.count == 2 {
                    validationStateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.title = "Valid Title"
        
        // Then
        wait(for: [validationStateExpectation], timeout: 1.0)
        XCTAssertEqual(validationStates, [false, true])
    }
    
    func testFieldSubscriptions_ClearsErrorsWhenValid() {
        // Given
        let expectation = expectation(description: "Field errors update")
        
        // When
        viewModel.title = "ab" // Should trigger error
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Verify error is set
            XCTAssertNotNil(self.viewModel.fieldErrors.value["title"])
            
            // Then set valid value
            self.viewModel.title = "Valid Title"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Verify error is cleared
                XCTAssertNil(self.viewModel.fieldErrors.value["title"])
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
} 