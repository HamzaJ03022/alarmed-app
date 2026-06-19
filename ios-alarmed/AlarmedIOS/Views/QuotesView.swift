import SwiftUI

struct QuotesView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var newQuote = ""
    @State private var editIndex: Int? = nil
    @State private var editText = ""
    @State private var showDeleteAlert = false
    @State private var deleteIndex: Int? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Add your own motivational quotes to see when you wake up. These quotes will be randomly shown after completing your alarm challenges.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                inputSection

                ScrollView {
                    LazyVStack(spacing: 0) {
                        Text("Your Quotes (\(viewModel.quotes.count))")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppColors.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                        ForEach(viewModel.quotes.indices, id: \.self) { index in
                            quoteRow(index: index)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Motivational Quotes")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete Quote", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let idx = deleteIndex {
                        viewModel.deleteQuote(index: idx)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this quote?")
            }
        }
    }

    private var inputSection: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Enter a new motivational quote...", text: $newQuote, axis: .vertical)
                .padding(16)
                .background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(AppColors.text)
                .lineLimit(3...6)

            Button(action: addQuote) {
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.text)
                    .frame(width: 56, height: 56)
                    .background(
                        newQuote.trimmingCharacters(in: .whitespaces).isEmpty
                            ? AppColors.inactive : AppColors.primary,
                        in: Circle()
                    )
            }
            .disabled(newQuote.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func quoteRow(index: Int) -> some View {
        if editIndex == index {
            VStack(spacing: 12) {
                TextField("Edit quote...", text: $editText, axis: .vertical)
                    .padding(12)
                    .background(AppColors.buttonInactive, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(2...4)

                HStack {
                    Spacer()
                    Button {
                        editIndex = nil
                        editText = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundStyle(AppColors.text)
                            .frame(width: 40, height: 40)
                            .background(AppColors.error, in: RoundedRectangle(cornerRadius: 8))
                    }
                    Button {
                        if !editText.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.updateQuote(index: index, quote: editText.trimmingCharacters(in: .whitespaces))
                            editIndex = nil
                            editText = ""
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.body.bold())
                            .foregroundStyle(AppColors.text)
                            .frame(width: 40, height: 40)
                            .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(16)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        } else {
            VStack(spacing: 12) {
                Text(viewModel.quotes[index])
                    .font(.body)
                    .foregroundStyle(AppColors.text)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Spacer()
                    Button {
                        editIndex = index
                        editText = viewModel.quotes[index]
                    } label: {
                        Image(systemName: "pencil")
                            .font(.body)
                            .foregroundStyle(AppColors.primary)
                            .padding(8)
                    }
                    Button {
                        deleteIndex = index
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundStyle(AppColors.error)
                            .padding(8)
                    }
                }
            }
            .padding(20)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.cardShadow, radius: 12, y: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private func addQuote() {
        let trimmed = newQuote.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.addQuote(trimmed)
        newQuote = ""
    }
}

#Preview {
    QuotesView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
