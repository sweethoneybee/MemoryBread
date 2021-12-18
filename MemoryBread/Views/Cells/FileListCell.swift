//
//  FileListCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/18.
//

import UIKit
import SnapKit

protocol FileListCellDelegate: AnyObject {
    func downloadButtonTapped(_ cell: UITableViewCell)
    func cancelButtonTapped(_ cell: UITableViewCell)
    func openButtonTapped(_ cell: UITableViewCell)
}

final class FileListCell: UITableViewCell {
    struct UIConstants {
        static let contentViewInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        static let contentViewSpacing = CGFloat(5)
        static let buttonInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }

    static let reuseIdentifier = "file-list-cell"
    
    weak var delegate: FileListCellDelegate?
    
    private var mainContainerView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .fill
        $0.layoutMargins = UIConstants.contentViewInsets
        $0.spacing = UIConstants.contentViewSpacing
        $0.isLayoutMarginsRelativeArrangement = true
    }
    
    private var iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
    }
    
    private var fileContainerView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .fill
    }
    
    private var fileNameLabel = UILabel().then {
        $0.font = .preferredFont(forTextStyle: .title3)
        $0.textAlignment = .left
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    
    private var fileSizeLabel = UILabel().then {
        $0.font = .preferredFont(forTextStyle: .caption1)
        $0.textAlignment = .left
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    
    private var progressView = UIProgressView().then {
        $0.progressTintColor = .systemPink
        $0.isHidden = true
    }
    
    private static func makeButton() -> UIButton {
        return UIButton().then {
            $0.tintColor = .white
            $0.backgroundColor = .systemPink
            $0.layer.cornerRadius = 5
            $0.isHidden = true
            $0.contentEdgeInsets = UIConstants.buttonInsets
        }
    }
    
    private var downloadButton = FileListCell.makeButton().then {
        $0.setTitle("다운", for: .normal)
        $0.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
    }
    
    private var cancelContainer = UIStackView().then {
        $0.axis = .vertical
        $0.distribution = .fill
        $0.alignment = .center
        $0.isHidden = true
    }
    
    private var cancelButton = FileListCell.makeButton().then {
        $0.setTitle("취소", for: .normal)
        $0.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }
    
    private var progressFileSizeLabel = UILabel().then {
        $0.font = .preferredFont(forTextStyle: .caption2)
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
        $0.isHidden = true
    }
    
    private var openButton = FileListCell.makeButton().then {
        $0.setTitle("열기", for: .normal)
        $0.addTarget(self, action: #selector(openButtonTapped), for: .touchUpInside)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(mainContainerView)
        
        mainContainerView.addArrangedSubview(iconImageView)
        mainContainerView.addArrangedSubview(fileContainerView)
        mainContainerView.addArrangedSubview(downloadButton)
        mainContainerView.addArrangedSubview(cancelContainer)
        mainContainerView.addArrangedSubview(openButton)
        
        fileContainerView.addArrangedSubview(fileNameLabel)
        fileContainerView.addArrangedSubview(fileSizeLabel)
        fileContainerView.addArrangedSubview(progressView)
        
        cancelContainer.addArrangedSubview(cancelButton)
        cancelContainer.addArrangedSubview(progressFileSizeLabel)
        
        // MARK: - layouts
        fileNameLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        fileSizeLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        progressView.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        mainContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented FileListCell")
    }
}

extension FileListCell {
    func configure(using file: FileObject, download: GDDownload?, isExist: Bool) {
        iconImageView.image = file.mimeType.image
        
        fileNameLabel.text = file.name
        
        let isDownloading = download != nil ? true : false
        fileSizeLabel.isHidden = isDownloading
        progressView.isHidden = !isDownloading
        downloadButton.isHidden = isDownloading || isExist
        cancelContainer.isHidden = !isDownloading
        openButton.isHidden = isDownloading || !isExist
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        fileSizeLabel.text = formatter.string(fromByteCount: file.size)
        
        if let download = download {
            progressView.progress = download.progress
            progressFileSizeLabel.text = String(format: "%@/%@",
                                                formatter.string(fromByteCount: download.totalBytesWritten),
                                                formatter.string(fromByteCount: file.size))
        }
    }
}

extension FileListCell {
    @objc
    private func downloadButtonTapped() {
        delegate?.downloadButtonTapped(self)
    }
    
    @objc
    private func cancelButtonTapped() {
        delegate?.cancelButtonTapped(self)
    }
    
    @objc
    private func openButtonTapped() {
        delegate?.openButtonTapped(self)
    }
    
    func updateProgress(_ progress: Float, totalBytesWritten: Int64, totalSize: Int64) {
        progressView.progress = progress
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        progressFileSizeLabel.text = String(format: "%@/%@",
                                            formatter.string(fromByteCount: totalBytesWritten),
                                            formatter.string(fromByteCount: totalSize))
    }
}

