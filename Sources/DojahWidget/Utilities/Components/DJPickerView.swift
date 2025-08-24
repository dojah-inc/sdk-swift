//
//  DJPickerView.swift
//
//
//  Created by Isaac Iniongun on 28/10/2023.
//

import UIKit

final class DJPickerView: BaseView {

    private let titleLabel = UILabel(text: "", font: .regular(13))
    private let leftIconImageView = UIImageView()
    private let valueLabel = UILabel(text: "")
    private let arrowdownImageView = UIImageView(
        image: .res("chevronDown"),
        size: 10
    )
    private lazy var valueStackView = HStackView(
        subviews: [leftIconImageView, valueLabel, arrowdownImageView],
        spacing: 10,
        alignment: .center
    )
    lazy var valueView = UIView(
        subviews: [valueStackView],
        height: 50,
        backgroundColor: .primaryGrey,
        borderWidth: 0.7,
        borderColor: .djBorder,
        radius: 5
    )
    private lazy var dropdownView: DropDown = {
        with(DropDown()) {
            $0.dataSource = selectionItems
            $0.textFont = .regular(15)
            $0.direction = .bottom
            $0.selectionAction = { [weak self] index, value in
                guard let self else { return }
                if self.showSelectedItem {
                    self.updateValue(value)
                }
                self.itemSelectionHandler?(value, index)
            }
        }
    }()
    var selectionItems = [String]() {
        didSet {
            dropdownView.dataSource = selectionItems
        }
    }

    private var itemSelectionHandler: StringIntParamHandler?
    private let showSelectedItem: Bool

    private lazy var contentStackView = VStackView(
        subviews: [titleLabel, valueView],
        spacing: 6
    )

    init(
        title: String,
        value: String = "",
        leftIconConfig: IconConfig = .init(),
        bgColor: UIColor = .primaryGrey,
        borderColor: UIColor = .djBorder,
        borderWidth: CGFloat = 0.7,
        showDropdownIcon: Bool = true,
        items: [String] = [],
        showSelectedItem: Bool = true,
        itemSelectionHandler: StringIntParamHandler? = nil
    ) {
        selectionItems = items
        self.showSelectedItem = showSelectedItem
        super.init(frame: .zero)
        titleLabel.text = title
        updateValue(value)
        updateLeftIcon(config: leftIconConfig)
        self.itemSelectionHandler = itemSelectionHandler
        arrowdownImageView.showView(showDropdownIcon)
        with(valueView) {
            $0.backgroundColor = bgColor
            $0.viewBorderWidth = borderWidth
            $0.borderColor = borderColor
        }
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()
        clearBackground()

        with(contentStackView) {
            addSubview($0)
            $0.fillSuperview()
        }

        with(valueStackView) {
            $0.centerYInSuperview()
            $0.anchor(
                leading: valueView.leadingAnchor,
                trailing: valueView.trailingAnchor,
                padding: .kinit(leftRight: 15)
            )
        }

        if selectionItems.isNotEmpty {
            valueView.didTap { [weak self] in
                self?.showItems()
            }
        }
    }

    private func showItems() {
        guard selectionItems.isNotEmpty else { return }
        with(dropdownView) {
            $0.anchorView = valueView
            $0.kwidth = valueView.width
            $0.bottomOffset = CGPoint(
                x: 0,
                y: ($0.anchorView?.plainView.bounds.height)!
            )
            $0.show()
        }
    }

    private func updateLeftIcon(config: IconConfig) {
        with(leftIconImageView) {
            $0.image = config.icon
            $0.contentMode = config.contentMode
            $0.constraintSize(config.size)
            if config.size == .zero {
                valueStackView.setCustomSpacing(0, after: leftIconImageView)
            }
        }
    }

    func updateInfo(country: Country) {
        with(country) {
            valueLabel.text = $0.name
            leftIconImageView.image = $0.flag
        }
    }

    func updateInfo(country: DJCountryDB) {
        with(country) {
            valueLabel.text = $0.countryName
            leftIconImageView.image = $0.flag
        }
    }

    func updateValue(_ value: String) {
        with(valueLabel) {
            $0.text = value.isEmpty ? "Select" : value
            $0.textColor = value.isEmpty ? .aSecondaryLabel : .aLabel
        }
    }

    public func selectItem(item: String, index: Int) {
        updateValue(item)
        self.itemSelectionHandler?(item, index)
    }

}
