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
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.md)

                inputSection

                ScrollView {
                    LazyVStack(spacing: 0) {
                        SectionHeader(title: "Your quotes · \(viewModel.quotes.count)")
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)

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
                .padding(Spacing.md)
                .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                .foregroundStyle(AppColors.text)
                .tint(AppColors.primary)
                .lineLimit(3...6)

            Button(action: addQuote) {
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.text)
                    .frame(width: 56, height: 56)
                    .background(
                        newQuote.trimmingCharacters(in: .whitespaces).isEmpty
                            ? AppColors.surfaceElevated : AppColors.primary,
                        in: Circle()
                    )
            }
            .disabled(newQuote.trimmingCharacters(in: .whitespaces).isEmpty)
            .buttonStyle(PressableStyle(scale: 0.92))
            .accessibilityLabel("Add quote")
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
                            .background(AppColors.surfaceElevated, in: Circle())
                    }
                    .accessibilityLabel("Cancel editing")
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
                            .background(AppColors.primary, in: Circle())
                    }
                    .accessibilityLabel("Save quote")
                }
            }
            .padding(Spacing.md)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(AppColors.primary.opacity(0.5), lineWidth: 1))
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xs)
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
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Edit quote")
                    Button {
                        deleteIndex = index
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundStyle(AppColors.error)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Delete quote")
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxs)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xs)
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
