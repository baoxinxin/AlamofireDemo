//
//  ViewController.swift
//  AlamofireDemo
//
//  Created by ZLY on 16/10/25.
//  Copyright © 2016年 BX. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UITableViewController {
    
    enum Sections: Int {
        
        case headers, body
    }
    
    //添加属性观察者(willSet与didSet),必须要声明清楚属性类型;
    //willSet可以带newName参数，didSet可以带oldName参数
    //属性初始化时，不调用；设置属性值时才调用
    
    var request: Alamofire.Request? {
        didSet {
            oldValue?.cancel()
            title = request?.description
            refreshControl?.endRefreshing()
            headers.removeAll()
            elapsedTime = nil
        }
    }
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var headers: [String: String] = [:]
    var body: String?
    var elapsedTime: TimeInterval?
    var identifier: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
    }
    
    func refresh() {
        request = Alamofire.request("https://httpbin.org/post", method: .post)
        guard let _ = self.request else {
            return
        }
        
        refreshControl?.beginRefreshing()
        let start = CACurrentMediaTime()
        let requestComplete:(HTTPURLResponse?, Result<String>) -> Void = { response, result in
            let end = CACurrentMediaTime()
            self.elapsedTime = end - start
            if let response = response {
                for (field, value) in response.allHeaderFields {
                    self.headers["\(field)"] = "\(value)"
                }
            }
            
            if let identifier = self.identifier {
                switch identifier {
                case "GET", "POST", "PUT", "DELETE":
                    self.body = result.value
                case "DOWNLOAD":
                    self.body = self.downloadedBodyString()
                default:
                    break
                }
            }
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
        
        if let request = self.request as? DataRequest {
            request.responseString(completionHandler: { response in
                requestComplete(response.response, response.result)
            })
        } else if let request = self.request as? DownloadRequest {
            request.responseString(completionHandler: { (response) in
                requestComplete(response.response, response.result)
            })
        }
    }
    
    private func downloadedBodyString() -> String {
        return ""
    }
}

//MARK: - UITableViewDataSource

extension ViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .headers:
            return headers.count
        case .body:
            return body == nil ? 0 : 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Sections(rawValue: indexPath.section)! {
        case .headers:
            var cell =  tableView.dequeueReusableCell(withIdentifier: "Header")
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "Header")
            }
            let field = headers.keys.sorted(by: <)[indexPath.row]
            let value = headers[field]
            cell?.textLabel?.text = field
            cell?.detailTextLabel?.text = value
            return cell!
        case  .body:
            var cell = tableView.dequeueReusableCell(withIdentifier: "Body")
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: "Body")
            }
            cell?.textLabel?.text = body
            print(body)
            return cell!
        }
    }
}

//MARK: - UITableViewDelegate

extension ViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.tableView(tableView, numberOfRowsInSection: section) == 0 {
            return ""
        }
        switch Sections(rawValue: section)! {
        case .headers:
            return "Headers"
        default:
            return "Body"
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Sections(rawValue: indexPath.section)! {
        case .body:
            return 300
        default:
            return tableView.rowHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if Sections(rawValue: section) == .body, let elapsedTime = elapsedTime {
            let elapsedTimeText = ViewController.numberFormatter.string(from: elapsedTime as NSNumber) ?? "???"
            return "Elapsed Time: \(elapsedTimeText) sec"
        }
        return ""
    }
}

