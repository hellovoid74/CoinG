//
//  ViewController.swift
//  CoinG
//
//  Created by Gleb Lanin on 12/03/2022.
//
//  CoinViewController.swift
//  CoinGeek
//
//  Created by Gleb Lanin on 01/02/2022.
//

import UIKit
import SnapKit
import RealmSwift

class CoinViewController: UIViewController{
    
    private var currencies: Results<CoinObject>?
    private var currenciesToDisplay: Results<CoinObject>?
    private var favCurrenices: Results<CoinObject>?
    private let manager = CryptoManager()
    private let dataRepository = DataRepository()
    private var tableView = UITableView()
    private var segmentedControl = UISegmentedControl()
    private var picker = PickerView()
    
    override func viewWillAppear(_ animated: Bool) {
        loadData()
        self.tableView.reloadData()
        print("entered")
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        //dataRepository.removeOldData()
        loadData()
        fetchAPIData()
        configureSegmentedControl()
        configureTable()
        configureUI()
        setNavBar()
    }
    
    //MARK: - Set TableView
    
    func configureTable(){
        currenciesToDisplay = dataRepository.loadTopobjects()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = Colors.main
        tableView.separatorStyle = .none
        let cellNib = UINib(nibName: "CustomCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "cell")
    }
    
    //MARK: - Set segmented control
    
    func configureSegmentedControl(){
        let sc = UISegmentedControl(items: Constants.segmentedValues)
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(handleSegmentChanged), for: .valueChanged)
        segmentedControl = sc
    }
    
    @objc fileprivate func handleSegmentChanged() {
        switch segmentedControl.selectedSegmentIndex{
        case 1:
            currenciesToDisplay = favCurrenices
        default:
            currenciesToDisplay = currencies
        }
        tableView.reloadData()
    }
    
    //MARK: - Receive new data from API
    
    func fetchAPIData(){
        dataRepository.printLocation()
        manager.performRequests()
    }
    
    func loadData(){
        currencies = dataRepository.loadTopobjects()
        favCurrenices = dataRepository.loadFavouriteObjects()
    }
    
    //MARK: - Set up UI elements
    
    func configureUI(){
        
        view.backgroundColor = Colors.main
        
        let infoLabel: UILabel = {
            let label = UILabel()
            label.frame.size.width = 300
            label.frame.size.height = 40
            label.numberOfLines = 0
            label.textColor = .white
            label.font = Fonts.mainFont
            label.text = Constants.welcomeText
            
            return label
        }()
        
        let lowerLabel: UILabel = {
            let label = UILabel()
            label.frame.size.width = 300
            label.frame.size.height = 20
            label.numberOfLines = 0
            label.textColor = .white
            label.font = Fonts.headerFont
            label.text = Constants.descriptionText
            
            return label
        }()
        
        let logoImage = UIImage(named: "wallet") ?? .none
        
        let logoImageView: UIImageView = {
            let imgView = UIImageView()
            imgView.contentMode = .scaleAspectFit
            imgView.clipsToBounds = true
            imgView.layer.cornerRadius = 75
            imgView.image = logoImage
            imgView.center = view.center
            
            return imgView
        }()
        
        [infoLabel, logoImageView, lowerLabel, tableView, segmentedControl].forEach {view.addSubview($0)}
        
        infoLabel.snp.makeConstraints {
            $0.centerX.equalTo(self.view)
            $0.top.equalTo(logoImageView.snp.bottom)
        }
        
        lowerLabel.snp.makeConstraints {
            $0.centerX.equalTo(self.view)
            $0.top.equalTo(infoLabel.snp.bottom)
        }
        
        logoImageView.snp.makeConstraints { make in
            make.height.equalTo(150)
            make.centerX.equalTo(self.view)
            make.top.equalToSuperview().inset(50)
            make.width.equalTo(150)
        }
        
        tableView.snp.makeConstraints {
            $0.centerX.equalTo(self.view)
            $0.width.equalTo(self.view.frame.width)
            $0.height.equalTo(300)
            $0.bottom.equalToSuperview()
        }
        
        segmentedControl.snp.makeConstraints{
            $0.bottom.equalTo(tableView.snp.top)
            $0.width.equalTo(view.snp.width).multipliedBy(0.9)
            $0.height.equalTo(40)
            $0.centerX.equalTo(view.snp.centerX)
        }
    }
    
    //MARK: - Set Up Navigation Bar
    
    func setNavBar() {
        let rightBarButton = UIBarButtonItem(image: Constants.Images.list, style: .plain, target: self, action: #selector(searchTapped))
        let switchBarButton = UIBarButtonItem(image: Constants.Images.globe, style: .plain, target: self, action: #selector(changeCurrencypressed))
        
        self.navigationItem.rightBarButtonItems = [rightBarButton, switchBarButton]
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.shadowImage = UIImage()
        
        let appearance = UINavigationBarAppearance()
        appearance.shadowColor = .clear
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.main
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }
    
    //MARK: - Handle pressed List button
    
    @objc fileprivate func searchTapped(){
        
        performSegue(withIdentifier: Constants.toListId, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.toCoinVC {
            let destinationVC = segue.destination as! DetailViewController
            
            if let indexPath = tableView.indexPathForSelectedRow{
                destinationVC.selectedDetail = currenciesToDisplay?[indexPath.row]
            }
        }
    }
    
    //MARK: - Handle change currency
    
    @objc fileprivate func changeCurrencypressed(){
        picker.addAlert(on: self)
    }
}

//MARK: - Tableview Datasource and Delegate methods

extension CoinViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? CustomCell else {
            fatalError()
        }
        cell.isUserInteractionEnabled = true
        cell.selectionStyle = .none
        
        let crypto = currenciesToDisplay?[indexPath.row]
        
        DispatchQueue.main.async {
            
            let value: Bool? = crypto?.change24h ?? 0 > 0 ? true : false
            
            switch value{
            case true:
                cell.changeLabel.textColor = .green
                cell.arrowImage.tintColor = .green
                cell.arrowImage.image = Constants.Images.triangleUp
            case false:
                cell.changeLabel.textColor = .red
                cell.arrowImage.tintColor = .red
                cell.arrowImage.image = Constants.Images.triangleDown
            default:
                cell.changeLabel.textColor = .lightGray
            }
            
            let selectedCurrency = UserDefaults.standard.string(forKey: Constants.currencyKey)
            guard let symbol = Constants.currencyDict[selectedCurrency ?? "usd"] else {return}
            
            cell.shortName.text = crypto?.symbol.uppercased()
            cell.valueLabel.text = String(format: "%.2f", crypto?.price ?? "") + " \(symbol)"
            cell.fullName.text = crypto?.name
            cell.changeLabel.text = String(format: "%.2f", crypto?.change24h ?? "") + " %"
            
            guard let url = URL(string: crypto?.imageUrl ?? "") else {return}
            ImageService.getImage(withURL: url) { image in
                cell.logoLabel.image = image
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = currenciesToDisplay?.count else {return 0}
        return count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Constants.toCoinVC, sender: self)
    }
}

extension UIView {
    var safeArea : ConstraintLayoutGuideDSL {
        return safeAreaLayoutGuide.snp
    }
}


