import Foundation

struct QuestionBank {
    static let mathQuestions: [Question] = [
        Question(id: "math-easy-1", category: "math", difficulty: "easy", question: "What is 8 + 12?", answer: "20"),
        Question(id: "math-easy-2", category: "math", difficulty: "easy", question: "What is 15 - 7?", answer: "8"),
        Question(id: "math-easy-3", category: "math", difficulty: "easy", question: "What is 6 × 4?", answer: "24"),
        Question(id: "math-easy-4", category: "math", difficulty: "easy", question: "What is 20 ÷ 5?", answer: "4"),
        Question(id: "math-easy-5", category: "math", difficulty: "easy", question: "What is 9 + 16?", answer: "25"),
        Question(id: "math-easy-6", category: "math", difficulty: "easy", question: "What is 7 + 8?", answer: "15"),
        Question(id: "math-easy-7", category: "math", difficulty: "easy", question: "What is 10 - 3?", answer: "7"),
        Question(id: "math-easy-8", category: "math", difficulty: "easy", question: "What is 5 × 5?", answer: "25"),
        Question(id: "math-easy-9", category: "math", difficulty: "easy", question: "What is 18 ÷ 3?", answer: "6"),
        Question(id: "math-easy-10", category: "math", difficulty: "easy", question: "What is 11 + 9?", answer: "20"),
        Question(id: "math-easy-11", category: "math", difficulty: "easy", question: "What is 14 + 6?", answer: "20"),
        Question(id: "math-easy-12", category: "math", difficulty: "easy", question: "What is 25 - 10?", answer: "15"),
        Question(id: "math-easy-13", category: "math", difficulty: "easy", question: "What is 3 × 7?", answer: "21"),
        Question(id: "math-easy-14", category: "math", difficulty: "easy", question: "What is 24 ÷ 4?", answer: "6"),
        Question(id: "math-easy-15", category: "math", difficulty: "easy", question: "What is 13 + 7?", answer: "20"),
        Question(id: "math-easy-16", category: "math", difficulty: "easy", question: "What is 30 - 12?", answer: "18"),
        Question(id: "math-easy-17", category: "math", difficulty: "easy", question: "What is 8 × 3?", answer: "24"),
        Question(id: "math-easy-18", category: "math", difficulty: "easy", question: "What is 35 ÷ 7?", answer: "5"),
        Question(id: "math-easy-19", category: "math", difficulty: "easy", question: "What is 17 + 3?", answer: "20"),
        Question(id: "math-easy-25", category: "math", difficulty: "easy", question: "What is 9 × 2?", answer: "18"),
        Question(id: "math-medium-1", category: "math", difficulty: "medium", question: "What is 13 × 7?", answer: "91"),
        Question(id: "math-medium-2", category: "math", difficulty: "medium", question: "What is 144 ÷ 12?", answer: "12"),
        Question(id: "math-medium-3", category: "math", difficulty: "medium", question: "What is 17 + 38?", answer: "55"),
        Question(id: "math-medium-5", category: "math", difficulty: "medium", question: "What is 8² (8 squared)?", answer: "64"),
        Question(id: "math-medium-7", category: "math", difficulty: "medium", question: "What is 63 ÷ 7?", answer: "9"),
        Question(id: "math-medium-10", category: "math", difficulty: "medium", question: "What is 12 × 6?", answer: "72"),
        Question(id: "math-medium-15", category: "math", difficulty: "medium", question: "What is 9² (9 squared)?", answer: "81"),
        Question(id: "math-medium-20", category: "math", difficulty: "medium", question: "What is 13 × 8?", answer: "104"),
        Question(id: "math-medium-24", category: "math", difficulty: "medium", question: "What is 7² (7 squared)?", answer: "49"),
        Question(id: "math-medium-29", category: "math", difficulty: "medium", question: "What is 11² (11 squared)?", answer: "121"),
        Question(id: "math-hard-1", category: "math", difficulty: "hard", question: "What is 17 × 23?", answer: "391"),
        Question(id: "math-hard-2", category: "math", difficulty: "hard", question: "What is the square root of 169?", answer: "13"),
        Question(id: "math-hard-3", category: "math", difficulty: "hard", question: "What is 15% of 240?", answer: "36"),
        Question(id: "math-hard-4", category: "math", difficulty: "hard", question: "If x + 7 = 22, what is x?", answer: "15"),
        Question(id: "math-hard-5", category: "math", difficulty: "hard", question: "What is (7 × 8) + (12 × 3)?", answer: "92"),
        Question(id: "math-hard-7", category: "math", difficulty: "hard", question: "What is the square root of 225?", answer: "15"),
        Question(id: "math-hard-9", category: "math", difficulty: "hard", question: "If 3x - 5 = 16, what is x?", answer: "7"),
        Question(id: "math-hard-14", category: "math", difficulty: "hard", question: "If 2x + 9 = 31, what is x?", answer: "11"),
        Question(id: "math-hard-17", category: "math", difficulty: "hard", question: "What is the square root of 144?", answer: "12"),
        Question(id: "math-hard-19", category: "math", difficulty: "hard", question: "If 4x - 8 = 28, what is x?", answer: "9"),
    ]

    static let generalQuestions: [Question] = [
        Question(id: "general-easy-1", category: "general", difficulty: "easy", question: "What is the capital of France?", options: ["London", "Berlin", "Paris", "Madrid"], answer: "Paris"),
        Question(id: "general-easy-2", category: "general", difficulty: "easy", question: "How many days are in a week?", answer: "7"),
        Question(id: "general-easy-3", category: "general", difficulty: "easy", question: "What planet is known as the Red Planet?", options: ["Venus", "Mars", "Jupiter", "Saturn"], answer: "Mars"),
        Question(id: "general-easy-4", category: "general", difficulty: "easy", question: "How many sides does a triangle have?", answer: "3"),
        Question(id: "general-easy-5", category: "general", difficulty: "easy", question: "What is the largest ocean on Earth?", options: ["Atlantic", "Indian", "Arctic", "Pacific"], answer: "Pacific"),
        Question(id: "general-easy-6", category: "general", difficulty: "easy", question: "How many legs does a spider have?", answer: "8"),
        Question(id: "general-easy-7", category: "general", difficulty: "easy", question: "What color is the sky on a clear day?", options: ["Green", "Blue", "Red", "Yellow"], answer: "Blue"),
        Question(id: "general-easy-9", category: "general", difficulty: "easy", question: "What do bees make?", options: ["Silk", "Honey", "Milk", "Butter"], answer: "Honey"),
        Question(id: "general-easy-10", category: "general", difficulty: "easy", question: "How many months are in a year?", answer: "12"),
        Question(id: "general-easy-11", category: "general", difficulty: "easy", question: "What is the capital of Italy?", options: ["Venice", "Rome", "Milan", "Naples"], answer: "Rome"),
        Question(id: "general-medium-1", category: "general", difficulty: "medium", question: "In what year did the Titanic sink?", answer: "1912"),
        Question(id: "general-medium-2", category: "general", difficulty: "medium", question: "Which element has the chemical symbol O?", options: ["Gold", "Oxygen", "Osmium", "Oganesson"], answer: "Oxygen"),
        Question(id: "general-medium-3", category: "general", difficulty: "medium", question: "How many bones are in the adult human body?", answer: "206"),
        Question(id: "general-medium-4", category: "general", difficulty: "medium", question: "Who painted the Mona Lisa?", options: ["Vincent van Gogh", "Pablo Picasso", "Leonardo da Vinci", "Michelangelo"], answer: "Leonardo da Vinci"),
        Question(id: "general-medium-5", category: "general", difficulty: "medium", question: "What is the capital of Japan?", options: ["Seoul", "Beijing", "Tokyo", "Bangkok"], answer: "Tokyo"),
        Question(id: "general-medium-6", category: "general", difficulty: "medium", question: "What is the largest mammal in the world?", options: ["Elephant", "Blue Whale", "Giraffe", "Polar Bear"], answer: "Blue Whale"),
        Question(id: "general-hard-1", category: "general", difficulty: "hard", question: "In what year was the first iPhone released?", answer: "2007"),
        Question(id: "general-hard-2", category: "general", difficulty: "hard", question: "What is the world's smallest country by land area?", options: ["Monaco", "Vatican City", "San Marino", "Liechtenstein"], answer: "Vatican City"),
        Question(id: "general-hard-3", category: "general", difficulty: "hard", question: "Who wrote War and Peace?", options: ["Charles Dickens", "Leo Tolstoy", "Jane Austen", "Mark Twain"], answer: "Leo Tolstoy"),
        Question(id: "general-hard-4", category: "general", difficulty: "hard", question: "What is the atomic number of gold?", answer: "79"),
    ]

    static let puzzleQuestions: [Question] = [
        Question(id: "puzzle-easy-1", category: "puzzle", difficulty: "easy", question: "Complete the pattern: 2, 4, 6, 8, ?", answer: "10"),
        Question(id: "puzzle-easy-2", category: "puzzle", difficulty: "easy", question: "Unscramble this word: LPAPE", answer: "apple"),
        Question(id: "puzzle-easy-3", category: "puzzle", difficulty: "easy", question: "What comes next? Monday, Tuesday, Wednesday, ?", answer: "thursday"),
        Question(id: "puzzle-easy-4", category: "puzzle", difficulty: "easy", question: "Complete the sequence: A, B, C, D, ?", answer: "e"),
        Question(id: "puzzle-easy-5", category: "puzzle", difficulty: "easy", question: "Unscramble this word: EOSUM", answer: "mouse"),
        Question(id: "puzzle-easy-6", category: "puzzle", difficulty: "easy", question: "Complete the pattern: 5, 10, 15, 20, ?", answer: "25"),
        Question(id: "puzzle-easy-11", category: "puzzle", difficulty: "easy", question: "Complete the pattern: 3, 6, 9, 12, ?", answer: "15"),
        Question(id: "puzzle-easy-16", category: "puzzle", difficulty: "easy", question: "Complete the pattern: 1, 3, 5, 7, ?", answer: "9"),
        Question(id: "puzzle-easy-21", category: "puzzle", difficulty: "easy", question: "Complete the pattern: 4, 8, 12, 16, ?", answer: "20"),
        Question(id: "puzzle-easy-24", category: "puzzle", difficulty: "easy", question: "Complete the sequence: 2, 4, 8, 16, ?", answer: "32"),
        Question(id: "puzzle-medium-1", category: "puzzle", difficulty: "medium", question: "Complete the pattern: 1, 1, 2, 3, 5, 8, ?", answer: "13"),
        Question(id: "puzzle-medium-3", category: "puzzle", difficulty: "medium", question: "What number completes the pattern? 5, 10, 20, 40, ?", answer: "80"),
        Question(id: "puzzle-medium-4", category: "puzzle", difficulty: "medium", question: "If CAT = 3, DOG = 3, BIRD = ?", answer: "4"),
        Question(id: "puzzle-medium-11", category: "puzzle", difficulty: "medium", question: "Complete the pattern: 2, 3, 5, 8, 13, ?", answer: "21"),
        Question(id: "puzzle-medium-13", category: "puzzle", difficulty: "medium", question: "What number completes the pattern? 4, 9, 16, 25, ?", answer: "36"),
        Question(id: "puzzle-hard-1", category: "puzzle", difficulty: "hard", question: "Complete the pattern: 2, 6, 12, 20, 30, ?", answer: "42"),
        Question(id: "puzzle-hard-2", category: "puzzle", difficulty: "hard", question: "If A=1, B=2, C=3... what does FACE equal?", answer: "21"),
        Question(id: "puzzle-hard-4", category: "puzzle", difficulty: "hard", question: "What completes the sequence? 3, 7, 15, 31, ?", answer: "63"),
        Question(id: "puzzle-hard-5", category: "puzzle", difficulty: "hard", question: "If 2+3=10, 4+5=36, then 6+7=?", answer: "84"),
        Question(id: "puzzle-hard-9", category: "puzzle", difficulty: "hard", question: "What completes the pattern? 1, 3, 6, 10, 15, ?", answer: "21"),
    ]

    static let allQuestions: [Question] = mathQuestions + generalQuestions + puzzleQuestions

    static func getRandomQuestions(count: Int, difficulty: String, categories: [String]) -> [Question] {
        let filtered = allQuestions.filter {
            $0.difficulty == difficulty && categories.contains($0.category)
        }
        return Array(filtered.shuffled().prefix(count))
    }
}
