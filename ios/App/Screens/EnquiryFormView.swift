import CatalogueCore
import SwiftUI

struct EnquiryFormView: View {
    @State private var viewModel: EnquiryViewModel
    @Environment(\.dismiss) private var dismiss

    init(product: Product, repository: CatalogueRepository) {
        _viewModel = State(initialValue: EnquiryViewModel(product: product, repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.phase == .sent {
                    thankYou
                } else {
                    form
                }
            }
            .navigationTitle("Enquire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.phase == .sent ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
    }

    private var form: some View {
        Form {
            Section {
                Text(viewModel.product.title).font(.headline)
            }
            Section("Your details") {
                field(.name, "Name", text: $viewModel.name, content: .name)
                field(.email, "Email", text: $viewModel.email, content: .emailAddress, keyboard: .emailAddress)
                field(.phone, "Phone (optional)", text: $viewModel.phone, content: .telephoneNumber, keyboard: .phonePad)
            }
            Section("Message (optional)") {
                TextField("What would you like to know?", text: $viewModel.message, axis: .vertical)
                    .lineLimit(3...8)
                    .accessibilityIdentifier("enquiry.message")
                error(for: .message)
            }
            Section {
                if let submitError = viewModel.submitError {
                    Text(submitError).foregroundStyle(.red).accessibilityIdentifier("enquiry.submitError")
                }
                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.phase == .submitting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Send enquiry").frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.phase == .submitting)
                .accessibilityIdentifier("enquiry.submit")
            }
        }
    }

    private var thankYou: some View {
        ContentUnavailableView {
            Label("Thank you", systemImage: "checkmark.circle.fill")
        } description: {
            Text("We've received your enquiry about \(viewModel.product.title) and will be in touch soon.")
        }
        .accessibilityIdentifier("enquiry.thankYou")
    }

    private func field(
        _ field: EnquiryViewModel.Field, _ title: String, text: Binding<String>,
        content: UITextContentType, keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading) {
            TextField(title, text: text)
                .textContentType(content)
                .keyboardType(keyboard)
                .textInputAutocapitalization(field == .name ? .words : .never)
                .autocorrectionDisabled(field != .name)
                .accessibilityIdentifier("enquiry.\(field.rawValue)")
            error(for: field)
        }
    }

    @ViewBuilder
    private func error(for field: EnquiryViewModel.Field) -> some View {
        if let message = viewModel.fieldErrors[field] {
            Text(message).font(.caption).foregroundStyle(.red)
        }
    }
}

#Preview {
    EnquiryFormView(product: PreviewCatalogueRepository.products[0], repository: PreviewCatalogueRepository())
}
