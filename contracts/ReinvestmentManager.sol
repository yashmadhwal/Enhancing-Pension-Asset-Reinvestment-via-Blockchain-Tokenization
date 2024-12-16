// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/AssetNFT.sol";

contract ReinvestmentManager {
    struct ReinvestmentPeriod {
        uint256 ID;
        uint256 start;
        uint256 end;
        uint256 rate;
        uint256 assetPrice;
        address currentAsset;
    }

    struct Portfolio {
        ReinvestmentPeriod reinvestmentPeriod;
        AssetNFT.AssetMetadata assetMetadata;
    }

    uint256 private constant ONE_HUNDRED = 10000; // 100 %

    uint256 private _rate;
    uint256 private _asset_price;
    uint256 private _reinvestmentID;
    mapping(uint256 => string) private _user_salt;
    uint256[] public _user_ids;
    mapping(uint256 => uint256) private _user_indexes;
    AssetNFT private _currentAsset;

    mapping(uint256 => uint256) public userBalance;
    mapping(uint256 => ReinvestmentPeriod) public passedReinvestmentPeriods;
    ReinvestmentPeriod public reinvestmentPeriod;
    address public assetVault;
    address[] public assets;
    address public admin;
    mapping(uint256 => Portfolio[]) public userPortfolio;

    constructor() {
        admin = msg.sender;
        _rate = 1000; // 10 %
        _asset_price = 1000;
        assetVault = msg.sender;
        newReinvestmentPeriod();
    }

    event userBatchAdded(
        uint256 reinvestmentPeriodID,
        AssetNFT.AssetMetadata[] metadata
    );
    event savingsReinvested(
        ReinvestmentPeriod reinvestmentPeriod,
        uint256[] userIDs,
        uint256[] newBalances
    );
    event userBatchTransfered(uint256[] userIDs, address to);

    function addUserBatch(
        uint256[] memory userIDs_,
        string[] memory salt_,
        uint256[] memory balance_
    ) external onlyAdmin {
        require(
            userIDs_.length == balance_.length,
            "user and balance arrays not of the same length"
        );
        require(
            userIDs_.length == salt_.length,
            "user and salt arrays not of the same length"
        );

        uint len = userIDs_.length;
        AssetNFT.AssetMetadata[]
            memory metadata_ = new AssetNFT.AssetMetadata[](len);
        uint256[] memory amounts_ = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            uint256 userID_ = userIDs_[i];
            require(!isUser(userID_), "user is already added");

            userBalance[userID_] = balance_[i];
            _user_salt[userID_] = salt_[i];
            _user_ids.push(userID_);
            _user_indexes[userID_] = _user_ids.length - 1;

            uint256 amount_ = balance_[i] / _asset_price;

            AssetNFT.AssetMetadata memory m_ = AssetNFT.AssetMetadata({
                userID: userID_,
                salt: salt_[i],
                savingsBalance: balance_[i],
                amount: amount_
            });
            amounts_[i] = amount_;
            metadata_[i] = m_;

            userPortfolio[userID_].push(Portfolio(reinvestmentPeriod, m_));
        }

        _currentAsset.mintNFTBatch(assetVault, userIDs_, metadata_);

        emit userBatchAdded(_reinvestmentID, metadata_);
    }

    // Reinvest savings for a given rate and mint new assets for every user
    function reinvestSavings() external onlyAdmin {
        reinvestmentPeriod.end = block.timestamp;
        passedReinvestmentPeriods[_reinvestmentID] = reinvestmentPeriod;
        newReinvestmentPeriod();

        uint len = _user_ids.length;
        uint256[] memory newBalances_ = new uint256[](len);
        AssetNFT.AssetMetadata[]
            memory metadata_ = new AssetNFT.AssetMetadata[](len);

        for (uint256 i = 0; i < _user_ids.length; i++) {
            uint256 userID_ = _user_ids[i];
            uint256 topUp_ = (userBalance[userID_] * _rate) / ONE_HUNDRED;
            userBalance[userID_] += topUp_;
            newBalances_[i] = userBalance[userID_];
            uint256 amount_ = userBalance[userID_] / _asset_price;
            metadata_[i] = AssetNFT.AssetMetadata({
                userID: userID_,
                salt: _user_salt[userID_],
                savingsBalance: userBalance[userID_],
                amount: amount_
            });
        }

        _currentAsset.mintNFTBatch(assetVault, _user_ids, metadata_);
        emit savingsReinvested(reinvestmentPeriod, _user_ids, newBalances_);
    }

    function setRate(uint256 rate_) external onlyAdmin {
        _rate = rate_;
        reinvestmentPeriod.rate = rate_;
    }

    function setAssetPrice(uint256 price_) external onlyAdmin {
        _asset_price = price_;
        reinvestmentPeriod.assetPrice = price_;
    }

    function newReinvestmentPeriod() internal {
        _reinvestmentID += 1;
        _currentAsset = new AssetNFT(
            address(this),
            msg.sender,
            _reinvestmentID
        );
        assets.push(address(_currentAsset));
        reinvestmentPeriod = ReinvestmentPeriod({
            ID: _reinvestmentID,
            rate: _rate, // 10 %
            start: block.timestamp,
            end: 0,
            assetPrice: _asset_price,
            currentAsset: address(_currentAsset)
        });
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function _checkAdmin() internal view virtual {
        require(msg.sender == admin, "no permission");
    }

    function getUserLength() external view returns (uint256) {
        return _user_ids.length;
    }

    function isUser(uint256 userID_) public view returns (bool) {
        return userBalance[userID_] != 0;
    }

    function transferUserBatch(
        uint256[] memory userIDs_,
        address to_
    ) external {
        for (uint256 i = 0; i < userIDs_.length; i++) {
            uint256 userID_ = userIDs_[i];
            require(userBalance[userID_] != 0, "user not found");

            uint256 index = _user_indexes[userID_];

            if (index != _user_ids.length - 1) {
                _user_ids[index] = _user_ids[_user_ids.length - 1];
                _user_indexes[_user_ids[_user_ids.length - 1]] = index;
            }
            _user_indexes[_user_ids.length - 1] = 0;
            _user_ids.pop();
            userBalance[userID_] = 0;
            _user_salt[userID_] = "";

            _currentAsset.transferUserAssets(userIDs_, to_);

            emit userBatchTransfered(userIDs_, to_);
        }
    }
}
