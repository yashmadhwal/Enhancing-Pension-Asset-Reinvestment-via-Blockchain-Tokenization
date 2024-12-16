// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract AssetNFT is ERC1155 {
    uint256 public _batch_size;
    uint256 public reinvestmentPeriod;
    mapping(uint256 => AssetMetadata) public assetMetadata;
    address private admin;
    address public vault;
    address public reinvestmentManager;

    struct AssetMetadata {
        uint256 userID;
        string salt;
        uint256 amount;
        uint256 savingsBalance;
    }

    event userBatchTransfered(address to_, uint256[] ids_, uint256[] amounts_);
    event userBatchAssetsMinted(uint256[] ids_, uint256[] amounts_);

    constructor(
        address manager_,
        address vault_,
        uint256 reinvestmentPeriod_
    ) ERC1155("") {
        reinvestmentPeriod = block.timestamp;
        admin = msg.sender;
        reinvestmentManager = manager_;
        vault = vault_;
        _batch_size = 1000;
        reinvestmentPeriod = reinvestmentPeriod_;
    }

    function mintNFTBatch(
        address assetVault,
        uint256[] memory userIds_,
        AssetMetadata[] memory metadata_
    ) public onlyAdmin {
        uint256 n = userIds_.length;
        uint256 max_j_ = n / _batch_size + 1;

        for (uint256 j = 0; j < max_j_; j++) {
            uint256 _start = _batch_size * j;
            uint256 _end = _batch_size * (j + 1);
            if (_end > n) {
                _end = n;
            }
            if (_start == _end) {
                break;
            }

            uint256[] memory _ids = new uint256[](_end - _start);
            uint256[] memory _amounts = new uint256[](_end - _start);

            for (uint256 i = _start; i < _end; i++) {
                uint256 userId_ = userIds_[i];
                assetMetadata[userId_] = metadata_[i];
                _amounts[i] = metadata_[i].amount;
                _ids[i] = userId_;
            }

            _mintBatch(assetVault, _ids, _amounts, "");
            emit userBatchAssetsMinted(_ids, _amounts);
        }
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function _checkAdmin() internal view virtual {
        require(msg.sender == admin || msg.sender == vault, "no permission");
    }

    function transferUserAssets(
        uint256[] memory userIDs_,
        address to_
    ) public onlyAdmin {
        uint256 n = userIDs_.length;
        uint256 _max_j = n / _batch_size + 1;

        for (uint256 j = 0; j < _max_j; j++) {
            uint256 start_ = _batch_size * j;
            uint256 end_ = _batch_size * (j + 1);
            if (end_ > n) {
                end_ = n;
            }
            if (start_ == end_) {
                break;
            }

            uint256[] memory ids_ = new uint256[](end_ - start_);
            uint256[] memory amounts_ = new uint256[](end_ - start_);

            for (uint256 i = start_; i < end_; i++) {
                uint256 userID_ = userIDs_[i];
                AssetMetadata memory metadata_ = assetMetadata[userID_];
                amounts_[i] = metadata_.amount;
                ids_[i] = userID_;
                assetMetadata[userID_] = AssetMetadata(0, "", 0, 0);
            }

            _safeBatchTransferFrom(vault, to_, ids_, amounts_, "");
            emit userBatchTransfered(to_, ids_, amounts_);
        }
    }

    function setBatchSize(uint256 size_) external {
        _batch_size = size_;
    }
}
