// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract DonationContract is ERC721, Ownable, ReentrancyGuard {


    
    // walletType[address] = WALLET_TYPE_TYPENAME
    uint8 public constant WALLET_TYPE_ORGANIZATION = 1;
    uint8 public constant WALLET_TYPE_INDIVIDUAL = 2;

    uint8 public constant FEE_PERCENT = 2;


    uint256 public contractRevenue;

    constructor() ERC721("DonationContract", "DNCT") Ownable(msg.sender) {}

    
    mapping(address => uint256) public wallets;
    mapping(address => uint8)   public walletTypes; 
    mapping(address => uint256) public operationalFundsWallets;
    mapping(address => uint8)   public operationalPercents;


    uint256 private _tokenId;

    struct donation {
        address donor;
        address receiver;
        uint256 amount;
        uint8   operationalPercent;
        uint256 timestamp;
    }

    mapping(uint256 => donation) public metadata;


    event DonateEvent(
        address indexed donor,
        address indexed receiver,
        uint256 amount,
        uint8   operationalPercent,
        uint256 timestamp,
        uint256 indexed tokenId
    );
    event CreateWalletEvent(
        address indexed owner,
        uint8   walletType,
        uint8   operationalPercent,
        uint256 timestamp
    );
    event WithdrawalEvent(
        address indexed owner,
        uint256 amount,
        uint256 timestamp
    );
    event DepositEvent(
        address indexed owner,
        uint256 amount,
        uint256 timestamp
    );
    event ContractRevenueWithdrawalEvent(
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );
    // 기존 이벤트들 아래에 추가
    event OperationalPercentUpdated(
        address indexed owner,
        uint8 oldPercent,
        uint8 newPercent,
        uint256 timestamp
    );

   
    // mint NFT
    function mintNFT(address _donor, address _receiver, uint256 _amount, uint8 _operationalPercent) private returns (uint256) {

        
        _safeMint(_donor, _tokenId);

        metadata[_tokenId] = donation(
            _donor,
            _receiver,
            _amount,
            _operationalPercent,
            block.timestamp
        );

        return _tokenId++;

    }


    string private _baseTokenURI; // base URI

    

    // set _baseTokenURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // return baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // return token metadata uri
    function tokenURI(uint256 _token) public view virtual override returns (string memory) {

        require(bytes(_baseURI()).length > 0, "base URI not set");
        require(_ownerOf(_token) != address(0), "URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), Strings.toString(_token)));
    }
    

    // check wallet is exist
    function walletExists(address _address) public view returns (bool) {
        return walletTypes[_address] == WALLET_TYPE_INDIVIDUAL || walletTypes[_address] == WALLET_TYPE_ORGANIZATION;
    }


    // create wallet (organization, individual)
    function createWallet(uint8 _walletType, uint8 _operationalPercent) external {

        require(!walletExists(msg.sender), "Wallet already exists for this address");
        require(_walletType == WALLET_TYPE_INDIVIDUAL || _walletType == WALLET_TYPE_ORGANIZATION, "Invalid wallet type");
        require(_operationalPercent >= 0 && _operationalPercent <= 100, "Operational percent must be between 0 and 100.");


        walletTypes[msg.sender] = _walletType;
        
        if(_walletType == WALLET_TYPE_ORGANIZATION) {
            operationalPercents[msg.sender] = _operationalPercent;
        }else{
            operationalPercents[msg.sender] = 0;
        }

        emit CreateWalletEvent(msg.sender, _walletType, operationalPercents[msg.sender], block.timestamp);

    }

    // update operational percent
    function updateOperationalPercent(uint8 _newOperationalPercent) external nonReentrant {
        require(walletTypes[msg.sender] == WALLET_TYPE_ORGANIZATION, "Caller is not an organization or wallet does not exist.");
        require(_newOperationalPercent >= 0 && _newOperationalPercent <= 100, "Operational percent must be between 0 and 100.");

        uint8 oldPercent = operationalPercents[msg.sender];
        operationalPercents[msg.sender] = _newOperationalPercent;

        emit OperationalPercentUpdated(msg.sender, oldPercent, _newOperationalPercent, block.timestamp);
    }


    
    // deposit 
    function deposit() external payable {
        require(walletExists(msg.sender), "Wallet does not exist. Please create a wallet first");
        
        require(msg.value > 0, "Deposit amount must be greater than zero");
        
        wallets[msg.sender] += msg.value;
        
        emit DepositEvent(msg.sender, msg.value, block.timestamp);
    }




    // donate
    function donate(address _receiver, uint256 _amount, uint8 _expectedOperationalPercent) external nonReentrant returns (bool) {


        require(_receiver != msg.sender, "Cannot donate to yourself");
        require(_amount > 0, 'The donation amount must be greater than the zero');
        require(wallets[msg.sender] >= _amount, 'Insufficient balance for donate');
        
        uint8 _donorType = walletTypes[msg.sender];
        uint8 _receiverType = walletTypes[_receiver];

        require(_donorType == WALLET_TYPE_INDIVIDUAL || _donorType == WALLET_TYPE_ORGANIZATION, "Invalid donor wallet type");
        require(_receiverType == WALLET_TYPE_INDIVIDUAL || _receiverType == WALLET_TYPE_ORGANIZATION, "Invalid receiver wallet type");


        bool isValidDonation = 
            (_donorType == WALLET_TYPE_INDIVIDUAL && _receiverType == WALLET_TYPE_ORGANIZATION) || 
            (_donorType == WALLET_TYPE_ORGANIZATION && _receiverType == WALLET_TYPE_ORGANIZATION) ||
            (_donorType == WALLET_TYPE_ORGANIZATION && _receiverType == WALLET_TYPE_INDIVIDUAL);
    
        require(isValidDonation, "Invalid donation type");


        uint8 _operationalPercent = operationalPercents[_receiver];


        if (_receiverType == WALLET_TYPE_ORGANIZATION) { 
            // individual | organization -> organization 

            require(_operationalPercent == _expectedOperationalPercent, "Operational percent has changed since you viewed it.");

            uint256 fee = (_amount * FEE_PERCENT) / 100;

            uint256 remainingAfterFee = _amount - fee;
            uint256 operationalFunds = (remainingAfterFee * _operationalPercent) / 100;
            
            contractRevenue += fee;
            operationalFundsWallets[_receiver] += operationalFunds;
            wallets[_receiver] += (remainingAfterFee - operationalFunds);


        } else if (_donorType == WALLET_TYPE_ORGANIZATION && _receiverType == WALLET_TYPE_INDIVIDUAL) { 
            // organization -> individual

            wallets[_receiver] += _amount;

        }

        

        wallets[msg.sender] -= _amount;

        uint256 token = mintNFT(msg.sender, _receiver, _amount, _operationalPercent);

        emit DonateEvent(msg.sender, _receiver, _amount, _operationalPercent, block.timestamp, token);

        return true;

    }
    


    // withdrawal my wallet
    function withdrawal(uint256 _amount) public nonReentrant {

        require(_amount > 0, "Withdrawal amount must be greater than zero");

        uint8 _senderType = walletTypes[msg.sender];
        

        require(_senderType == WALLET_TYPE_INDIVIDUAL || _senderType == WALLET_TYPE_ORGANIZATION, "Invalid wallet type");

        if (_senderType == WALLET_TYPE_INDIVIDUAL) {

            require(wallets[msg.sender] >= _amount, 'Insufficient balance for withdrawal');
            wallets[msg.sender] -= _amount;
        } else {

            require(operationalFundsWallets[msg.sender] >= _amount, 'Insufficient operational funds for withdrawal');
            operationalFundsWallets[msg.sender] -= _amount;
        }
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to withdraw");
        
        emit WithdrawalEvent(msg.sender, _amount, block.timestamp);
    }

    // withdrawal contractRevenue
    function withdrawContractRevenue(address payable _recipient, uint256 _amount) external onlyOwner nonReentrant {
        require(_recipient != address(0), "Cannot withdraw to the zero address");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(contractRevenue >= _amount, "Insufficient contract revenue for withdrawal");

        contractRevenue -= _amount;

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to withdraw ContractRevenue");

        emit ContractRevenueWithdrawalEvent(_recipient, _amount, block.timestamp);
    }

}
