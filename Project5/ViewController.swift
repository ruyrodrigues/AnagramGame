import UIKit

class ViewController: UITableViewController {
    
    //MARK: - Variables and Constants
    var allWords = [String]()
    var usedWords = [String]()
    var randomWord = ""

    
    //MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnwser))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "New Game", style: .plain, target: self, action: #selector(startGame))
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        let defaults = UserDefaults.standard
        let jsonDecoder = JSONDecoder()
        
        if let savedTitle = defaults.object(forKey: "title") as? Data {
            guard let savedWordsUser = defaults.object(forKey: "usedWords") as? Data else { return }
            
            do {
                usedWords = try jsonDecoder.decode([String].self, from: savedWordsUser)
                title = try jsonDecoder.decode(String.self, from: savedTitle)
            } catch {
                fatalError()
            }
        } else {
            startGame()
        }
              
    }

    
    //MARK: - TableView Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row].capitalized
        cell.textLabel?.font = cell.textLabel?.font.withSize(18)
        return cell
    }
    
    //MARK: - Methods
    @objc func startGame() {
        guard let randomWord = allWords.randomElement()?.capitalized else { return }
        title = randomWord
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
        save()
    }

    @objc func promptForAnwser() {
        let alertController = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) {
            [weak self, weak alertController] _ in
            guard let answer = alertController?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        
        alertController.addAction(submitAction)
        present(alertController, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        
        if answer.count == 0 || lowerAnswer == title?.lowercased() {
            return
        } else {
            if isPossible(word: lowerAnswer) {
                if isOriginal(word: lowerAnswer) {
                    if isReal(word: lowerAnswer) {
                        usedWords.insert(lowerAnswer, at: 0)
                        let indexPath = IndexPath(row: 0, section: 0)
                        tableView.insertRows(at: [indexPath], with: .automatic)
                        save()
                        return
                        
                    } else {
                        showErrorMessage(title: "Word not recognized", message: "You can't just make them up, you know!")
                    }
                } else {
                    showErrorMessage(title:"Word already used", message: "Be more you original, you can do it!")
                }
            } else {
                guard let title = title else { return }
                showErrorMessage(title: "Word not possible", message: "You can't spell that word from \(title.lowercased())")
            }
        }
    }
    
    
    func isPossible(word: String) -> Bool {
        if word.count > 2 {
            guard var tempWord = title?.lowercased() else { return false }
            
            for letter in word {
                if let position = tempWord.firstIndex(of: letter) {
                    tempWord.remove(at: position)
                } else {
                    return false
                }
            }
            return true
            
        } else {
            return false
        }
    }
    
    func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word.lowercased())
    }
    
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
        }
    
    
    func showErrorMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alertController, animated: true)
    }
    
    func save() {
        let jsonEncoder = JSONEncoder()
        
        guard let savedData = try? jsonEncoder.encode(usedWords) else { return }
        let defaultsWordsUsed = UserDefaults.standard
        defaultsWordsUsed.set(savedData, forKey: "usedWords")
        
        guard let savedData = try? jsonEncoder.encode(title) else { return }
        let defaultsWord = UserDefaults.standard
        defaultsWord.set(savedData, forKey: "title")
        
    }
    

}
