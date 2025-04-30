import UIKit
import DGCharts

struct Transaction: Codable {
    var type: String // "Gelir" veya "Gider"
    var category: String
    var amount: Double
    var date: Date // Tarih
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var transactionTableView: UITableView!
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var incomePieChartView: PieChartView!
    @IBOutlet weak var expensePieChartView: PieChartView!
    
    var balance: Double = 0.0
    var transactions: [Transaction] = []
    
    let incomeCategories = ["Maaş", "Prim", "Hediye", "Diğer"]
    let expenseCategories = ["Market", "Kira", "Eğlence", "Ulaşım", "Diğer"]
    
    var selectedCategory: String?
    var isIncome: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        // Kredi kartı arka plan resmi
        let creditCardImageView = UIImageView(image: UIImage(named: "creditCardImage"))
        creditCardImageView.contentMode = .scaleAspectFill
        creditCardImageView.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: 80)
        self.view.addSubview(creditCardImageView)
        self.view.sendSubviewToBack(creditCardImageView)

        transactionTableView.delegate = self
        transactionTableView.dataSource = self

        loadTransactionsFromFile()
        updateBalance()
        updateBalanceLabel()
        updatePieChart()
    }

    // MARK: - Dosya Yolu
    func getTransactionsFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent("transactions.json")
    }

    // MARK: - Veri Kaydet / Yükle
    func saveTransactionsToFile() {
        do {
            let data = try JSONEncoder().encode(transactions)
            try data.write(to: getTransactionsFileURL())
        } catch {
            print("Veri kaydedilemedi: \(error)")
        }
    }

    func loadTransactionsFromFile() {
        do {
            let data = try Data(contentsOf: getTransactionsFileURL())
            transactions = try JSONDecoder().decode([Transaction].self, from: data)
        } catch {
            print("Veri yüklenemedi: \(error)")
        }
    }

    // MARK: - Bakiye Güncelleme
    func updateBalance() {
        balance = transactions.reduce(0.0) { $0 + ($1.type == "Gelir" ? $1.amount : -$1.amount) }
    }

    func updateBalanceLabel() {
        balanceLabel.text = String(format: "%.2f₺", balance)
        balanceLabel.textAlignment = .center
        balanceLabel.font = UIFont.boldSystemFont(ofSize: 24)
        balanceLabel.textColor = UIColor.black
        balanceLabel.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: 60)
    }

    // MARK: - Pie Chart
    func updatePieChart() {
        var incomeTotal = 0.0
        var expenseTotal = 0.0
        var incomeCategoriesTotal: [String: Double] = [:]
        var expenseCategoriesTotal: [String: Double] = [:]

        for transaction in transactions {
            if transaction.type == "Gelir" {
                incomeTotal += transaction.amount
                incomeCategoriesTotal[transaction.category, default: 0.0] += transaction.amount
            } else {
                expenseTotal += transaction.amount
                expenseCategoriesTotal[transaction.category, default: 0.0] += transaction.amount
            }
        }

        // GELİR GRAFİĞİ
        if incomeCategoriesTotal.isEmpty {
            let entry = PieChartDataEntry(value: 1.0, label: "")
            let dataSet = PieChartDataSet(entries: [entry], label: "Gelir Dağılımı")
            dataSet.colors = [UIColor.lightGray]
            dataSet.drawValuesEnabled = false
            dataSet.entryLabelColor = .clear
            incomePieChartView.data = PieChartData(dataSet: dataSet)
        } else {
            let entries = incomeCategoriesTotal.map { PieChartDataEntry(value: $0.value, label: $0.key) }
            let dataSet = PieChartDataSet(entries: entries, label: "Gelir Dağılımı")
            dataSet.colors = [UIColor.green, UIColor.blue, UIColor.cyan, UIColor.purple]
            dataSet.drawValuesEnabled = false
            dataSet.entryLabelColor = .clear
            incomePieChartView.data = PieChartData(dataSet: dataSet)
        }

        // GİDER GRAFİĞİ
        if expenseCategoriesTotal.isEmpty {
            let entry = PieChartDataEntry(value: 1.0, label: "")
            let dataSet = PieChartDataSet(entries: [entry], label: "Gider Dağılımı")
            dataSet.colors = [UIColor.lightGray]
            dataSet.drawValuesEnabled = false
            dataSet.entryLabelColor = .clear
            expensePieChartView.data = PieChartData(dataSet: dataSet)
        } else {
            let entries = expenseCategoriesTotal.map { PieChartDataEntry(value: $0.value, label: $0.key) }
            let dataSet = PieChartDataSet(entries: entries, label: "Gider Dağılımı")
            dataSet.colors = [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.brown, UIColor.darkGray]
            dataSet.drawValuesEnabled = false
            dataSet.entryLabelColor = .clear
            expensePieChartView.data = PieChartData(dataSet: dataSet)
        }

        // GENEL GELİR-GİDER GRAFİĞİ
        let entries = [
            PieChartDataEntry(value: incomeTotal, label: ""),
            PieChartDataEntry(value: expenseTotal, label: "")
        ]
        let dataSet = PieChartDataSet(entries: entries, label: "Gelir-Gider Dağılımı")
        dataSet.colors = [UIColor.green, UIColor.red]
        dataSet.drawValuesEnabled = false
        dataSet.entryLabelColor = .clear
        pieChartView.data = PieChartData(dataSet: dataSet)
        pieChartView.centerText = ""
        pieChartView.notifyDataSetChanged()
    }

    // MARK: - Ekleme
    @IBAction func addIncomeTapped(_ sender: UIButton) {
        isIncome = true
        showCategorySelectionAlert(for: incomeCategories)
    }

    @IBAction func addExpenseTapped(_ sender: UIButton) {
        isIncome = false
        showCategorySelectionAlert(for: expenseCategories)
    }

    func showCategorySelectionAlert(for categories: [String]) {
        let alert = UIAlertController(title: "Kategori Seçin", message: nil, preferredStyle: .actionSheet)
        for category in categories {
            alert.addAction(UIAlertAction(title: category, style: .default) { _ in
                self.selectedCategory = category
                self.confirmTransaction()
            })
        }
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }

    func confirmTransaction() {
        guard let amountText = amountTextField.text,
              let amount = Double(amountText),
              let category = selectedCategory else {
            showAlert(message: "Lütfen geçerli bir tutar ve kategori seçin.")
            return
        }

        let type = isIncome ? "Gelir" : "Gider"
        let newTransaction = Transaction(type: type, category: category, amount: amount, date: Date())
        transactions.insert(newTransaction, at: 0)

        updateBalance()
        updateBalanceLabel()
        transactionTableView.reloadData()
        amountTextField.text = ""
        updatePieChart()
        saveTransactionsToFile()
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transaction = transactions[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateString = formatter.string(from: transaction.date)

        cell.textLabel?.text = "\(transaction.type): \(transaction.category)"
        cell.detailTextLabel?.text = "\(String(format: "%.2f₺", transaction.amount)) • \(dateString)"
        cell.textLabel?.textColor = transaction.type == "Gelir" ? .systemGreen : .systemRed
        return cell
    }
}
