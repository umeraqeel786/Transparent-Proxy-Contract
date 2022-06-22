// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DroneContract is
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 public droneId;
    uint256 public mintSupplyLimit;
    bool public mintEnabled;
    string public baseUri;
    uint256 private value; // added in upgrade

    struct Drones {
        uint256 price;
        address ownerAddress;
        bool listedOnSale;
        string metadataHash;
    }

    struct ReturnDroneInfo {
        uint256 droneID;
        string metadataHash;
    }

    mapping(uint256 => Drones) public drones;
    mapping(address => bool) public whitelistedAdminAddresses;

    error PriceNotMatched(uint256 droneId, uint256 price);
    error PriceMustBeAboveZero();
    error NotOwnerOfDrone();
    error InvalidMetadataHash();
    error InvaliddroneId();
    error MintingDisabled();
    error NotWhitelistedAdmin();
    error DroneMintSupplyReached();
    error DroneNotExist();
    error OwnerCannotBuyHisOwnDrone();
    error OwnerTransferredTokenExternally();
    error PlayerHoldZeroDrone();
    error NewLimitShouldBeGreaterThanExisting(
        uint256 existingLimit,
        uint256 newLimit
    );

    event UpdatedDroneStatusForSale(
        uint256 droneId,
        address ownerAddress,
        uint256 price
    );

    event UpdatedDroneStatusToNotForSale(uint256 droneId, address ownerAddress);

    event DroneBought(uint256 droneId, address buyer, uint256 price);

    event UpdatedDronePrice(
        uint256 droneId,
        address ownerAddress,
        uint256 price
    );

    event AddedWhitelistAdmin(address whitelistedAddress, address updatedBy);

    event RemovedWhitelistAdmin(address whitelistedAddress, address updatedBy);

    event SetBaseURI(string baseURI, address addedBy);

    event UpdateMetadata(uint256 droneId, string newHash, address updatedBy);

    event MintStatusUpdated(bool status, address updatedBy);

    event DroneMinted(
        uint256 droneId,
        address ownerAddress,
        string metadataHash
    );

    event DroneRevertedFromSale(
        uint256 droneId,
        address lastOwnerAddress,
        address newOwnerAddress,
        bool saleStatus
    );

    event MintLimitUpdated(uint256 newLimit, address updatedBy);

    function initialize(uint256 _mintSupplyLimit) public initializer {
        __ERC721_init("Drones", "TB2");
        __Ownable_init();
        mintSupplyLimit = _mintSupplyLimit;
        mintEnabled = true;
        baseUri = "https://gateway.pinata.cloud/ipfs/";

        emit SetBaseURI(baseUri, msg.sender);
    }

    // constructor(uint _mintSupplyLimit) ERC721("Drones", "TB2") {
    //     mintSupplyLimit = _mintSupplyLimit;
    //     mintEnabled = true;
    //     baseUri = "https://gateway.pinata.cloud/ipfs/";

    //     emit SetBaseURI(baseUri, msg.sender);
    // }

    modifier droneExists(uint256 _droneId) {
        require(_exists(_droneId), "This drone does not exist.");
        _;
    }

    modifier isListedForSale(uint256 _droneId) {
        require(drones[_droneId].listedOnSale, "This drone is not listed yet");
        _;
    }

    modifier onlyOwnerOfDrone(uint256 _droneId) {
        if (ownerOf(_droneId) != msg.sender) {
            revert NotOwnerOfDrone();
        }
        _;
    }

    modifier notOwnerOfDrone(uint256 _droneId) {
        if (ownerOf(_droneId) == msg.sender) {
            revert OwnerCannotBuyHisOwnDrone();
        }
        _;
    }

    modifier onlyWhitelistedAddress() {
        if (!whitelistedAdminAddresses[msg.sender]) {
            revert NotWhitelistedAdmin();
        }
        _;
    }

    /**
     * @dev tokenURI is used to get tokenURI link.
     *
     * @param _tokenId - ID of drone
     *
     * @return string .
     */

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) {
            revert DroneNotExist();
        }
        return string(abi.encodePacked(baseUri, drones[_tokenId].metadataHash));
    }

    /**
     * @dev setBaseUri is used to set BaseURI.
     * Requirement:
     * - This function can only called by owner of contract
     *
     * @param _baseUri - New baseURI
     * Emits a {UpdatedBaseURI} event.
     */

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;

        emit SetBaseURI(baseUri, msg.sender);
    }

    /**
     * @dev updateMetadataHash is used to update the metadata of a drone.
     * Requirement:
     * - This function can only called by owner of the drone

     * @param _droneId - drone Id 
     * @param _droneMetadataHash - New Metadata
     * Emits a {UpdateMetadata} event.
     */
    function updateMetadataHash(
        uint256 _droneId,
        string calldata _droneMetadataHash
    ) external droneExists(_droneId) onlyOwner {
        drones[_droneId].metadataHash = _droneMetadataHash;

        emit UpdateMetadata(_droneId, _droneMetadataHash, msg.sender);
    }

    /**
     * @dev updateMintStatus is used to update miintng status.
     * Requirement:
     * - This function can only called by owner of the Contract

     * @param _status - status of drone Id 
     */

    function updateMintStatus(bool _status) external onlyOwner {
        mintEnabled = _status;

        emit MintStatusUpdated(_status, msg.sender);
    }

    /**
     * @dev updateMintLimit is used to update minting limit.
     * Requirement:
     * - This function can only called by owner of the Contract

     * @param newLimit - new Limit of minting 
     */

    function updateMintLimit(uint256 newLimit) external onlyOwner {
        if (newLimit <= mintSupplyLimit)
            revert NewLimitShouldBeGreaterThanExisting(
                mintSupplyLimit,
                newLimit
            );

        mintSupplyLimit = newLimit;

        emit MintLimitUpdated(mintSupplyLimit, msg.sender);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );

        if (
            drones[tokenId].listedOnSale && from == drones[tokenId].ownerAddress
        ) {
            drones[tokenId].listedOnSale = false;
            drones[tokenId].ownerAddress = to;
        } else {
            drones[tokenId].ownerAddress = to;
        }

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );

        if (
            drones[tokenId].listedOnSale && from == drones[tokenId].ownerAddress
        ) {
            drones[tokenId].listedOnSale = false;
            drones[tokenId].ownerAddress = to;
        } else {
            drones[tokenId].ownerAddress = to;
        }

        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev mintDrone is used to create a new drone.
     * Requirement:     

     * @param _droneMetadataHash - drone metadata 
     */

    function mintDrone(string memory _droneMetadataHash)
        external
        nonReentrant
        onlyWhitelistedAddress
    {
        droneId++;
        if (bytes(_droneMetadataHash).length != 46) {
            revert InvalidMetadataHash();
        }

        if (!mintEnabled) {
            revert MintingDisabled();
        }
        if (totalSupply() >= mintSupplyLimit) {
            revert DroneMintSupplyReached();
        }

        drones[droneId] = Drones(0, msg.sender, false, _droneMetadataHash);

        emit DroneMinted(droneId, msg.sender, _droneMetadataHash);

        _safeMint(msg.sender, droneId);
    }

    /**
     * @dev updateDroneToSale is used to list a new drone.
     * Requirement:
     * - This function can only called by owner of the drone
     *
     * @param _droneId - drone Id
     * @param _price - Price of the drone
     * Emits a {UpdatedDroneStatusForSale} event when player address is new.
     */

    function updateDroneToSale(uint256 _droneId, uint256 _price)
        external
        onlyOwnerOfDrone(_droneId)
    {
        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        drones[_droneId].listedOnSale = true;
        drones[_droneId].price = _price;

        emit UpdatedDroneStatusForSale(_droneId, msg.sender, _price);
    }

    /**
     * @dev getDroneInfo is used to get information of listing drone.
     *
     * @param _droneId - ID of drone
     *
     * @return listing Tuple.
     */

    function getDroneInfo(uint256 _droneId)
        external
        view
        returns (Drones memory)
    {
        return drones[_droneId];
    }

    /**
     * @dev updateDroneStatusToNotForSale is used to remove drone from listng.
     * Requirement:
     * - This function can only called by owner of the drone
     *
     * @param _droneId - drone Id
     * Emits a {UpdatedDroneStatusToNotForSale} event when player address is new.
     */

    function updateDroneStatusToNotForSale(uint256 _droneId)
        external
        isListedForSale(_droneId)
        onlyOwnerOfDrone(_droneId)
    {
        drones[_droneId].listedOnSale = false;

        emit UpdatedDroneStatusToNotForSale(_droneId, msg.sender);
    }

    /**
     * @dev buyDrone is used to buy drone which user has listed.
     * Requirement:
     * - This function can only called by anyone who wants to purchase drone
     *
     * @param _droneId - drone Id
     * Emits a {DroneBought} event when player address is new.
     */

    function buyDrone(uint256 _droneId)
        external
        payable
        isListedForSale(_droneId)
        notOwnerOfDrone(_droneId)
    {
        if (drones[_droneId].ownerAddress != ownerOf(_droneId)) {
            revert OwnerTransferredTokenExternally();
        }
        if (msg.value != drones[_droneId].price) {
            revert PriceNotMatched(_droneId, drones[_droneId].price);
        }

        emit DroneBought(_droneId, msg.sender, drones[_droneId].price);

        _safeTransfer(drones[_droneId].ownerAddress, msg.sender, _droneId, "");

        drones[_droneId].ownerAddress = msg.sender;
        drones[_droneId].listedOnSale = false;
    }

    /**
     * @dev updateDronePrice is used to update the price of a drone.
     * Requirement:
     * - This function can only called by owner of the drone

     * @param _droneId - drone Id 
     * @param _newPrice - Price of the drone
     * Emits a {UpdatedDronePrice} event when player address is new.
     */

    function updateDronePrice(uint256 _droneId, uint256 _newPrice)
        external
        isListedForSale(_droneId)
        onlyOwnerOfDrone(_droneId)
        nonReentrant
    {
        if (_newPrice <= 0) {
            revert PriceMustBeAboveZero();
        }
        drones[_droneId].price = _newPrice;

        emit UpdatedDronePrice(_droneId, msg.sender, _newPrice);
    }

    /**
     * @dev addWhitelistAddress is used to whitelsit admin account.
     * Requirement:
     * - This function can only called by owner of the contract

     * @param _account - Account to be whitelisted 
     * Emits a {AddedWhitelistAdmin} event when player address is new.
     */

    function addWhitelistAddress(address _account) external onlyOwner {
        whitelistedAdminAddresses[_account] = true;
        emit AddedWhitelistAdmin(_account, msg.sender);
    }

    /**
     * @dev removeWhitelistAdmin is used to whitelsit admin account.
     * Requirement:
     * - This function can only called by owner of the contract

     * @param _account - Account to be whitelisted 
     * Emits a {RemovedWhitelistAdmin} event when player address is new.
     */

    function removeWhitelistAdmin(address _account) external onlyOwner {
        whitelistedAdminAddresses[_account] = false;
        emit RemovedWhitelistAdmin(_account, msg.sender);
    }

    /**
     * @dev getAllDrones is used to get information of all drones.
     */

    function getAllDrones() external view returns (Drones[] memory) {
        Drones[] memory dronesList = new Drones[](totalSupply());

        for (uint256 i = 1; i <= totalSupply(); i++) {
            dronesList[i - 1] = drones[i];
        }

        return dronesList;
    }

    /**
     * @dev getDronesByAddress is used to get information of all drones.
     */

    function getDronesByAddress(address playerAddress)
        external
        view
        returns (ReturnDroneInfo[] memory)
    {
        ReturnDroneInfo[] memory droneInfo = new ReturnDroneInfo[](
            balanceOf(playerAddress)
        );

        if (balanceOf(playerAddress) == 0) return droneInfo;

        uint256 droneIndex = 0;

        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (ownerOf(i) == playerAddress) {
                droneInfo[droneIndex].droneID = i;
                droneInfo[droneIndex].metadataHash = string(
                    abi.encodePacked(baseUri, drones[i].metadataHash)
                );
                droneIndex++;
            }
        }
        return droneInfo;
    }

    //// added in upgrade

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store_value_TPPV1(uint256 newValue) public {
        value = newValue;
        //   emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve_value_TPPV1() public view returns (uint256) {
        return value;
    }
}
