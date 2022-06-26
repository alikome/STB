// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract TastyTest2 is 
    ERC721, 
    Ownable, 
    ReentrancyGuard
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    bytes32 public rootGA;
    
    address proxyRegistryAddress;

    uint256 public maxSupply = 100;

    string public baseURI = "ipfs://QmQSfWwHD27sYjqJwrted6dyw87ScZMRffqTk5WZYujLdJ/"; 
    string public notRevealedUri = "ipfs://QmYUuwLoiRb8woXwJCCsr1gvbr8E21KuxRtmVBmnH1tZz7/hidden.json";
    string public baseExtension = ".json";

    bool public paused = true;
    bool public revealed = true;
    bool public presaleM = true;
    bool public publicM = false;
    bool public giveawayM = true;

    uint256 presaleAmountLimit = 5; //max mint per wallet
    mapping(address => uint256) public _presaleClaimed;

    uint256 ownerAmountLimit = 20; //max mint per wallet for Owner
    mapping(address => uint256) public _ownerClaimed;

    uint256 giveawayAmountLimit = 1; //max mint per wallet for Giveaway
    mapping(address => uint256) public _giveawayClaimed;

    uint256 _price = 9000000000000000; // 0.009 ETH

    Counters.Counter private _tokenIds;

    constructor(
        string memory uri, 
        bytes32 merkleroot, 
        bytes32 merklerootGA,
        address _proxyRegistryAddress
        )
        ERC721("TastyTest", "TTT")
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
        root = merkleroot;
        rootGA = merklerootGA;
        proxyRegistryAddress = _proxyRegistryAddress;

        setBaseURI(uri);
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
        root = merkleroot;
    }

    function setMerkleRootGA(bytes32 merklerootGA) 
    onlyOwner 
    public 
    {
        rootGA = merklerootGA;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "NA origin");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "NA origin");
        _;
   }

   modifier isValidMerkleProofGA(bytes32[] calldata _proofGA) {
         require(MerkleProof.verify(
            _proofGA,
            rootGA,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "NA origin");
        _;
   }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function togglegiveAway() public onlyOwner {
        giveawayM = !giveawayM;
    }


    function presaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "NA");
        require(presaleM,                       "Presale is OFF");
        require(!paused,                        "Contract is paused");
        require(
            _amount <= presaleAmountLimit,      "Mint limit exceeded");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "Mint limit exceeded");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "Not enough ethers sent"
        );
             
        _presaleClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function giveAwayMint(address account, uint256 _amount, bytes32[] calldata _proofGA)
    external
    payable
    isValidMerkleProofGA(_proofGA)
    onlyAccounts
    {
        require(msg.sender == account,          "NA");
        require(giveawayM,                       "Giveaway is OFF");
        require(!paused,                        "Contract is paused");
        require(
            _amount <= giveawayAmountLimit,      "Mint limit exceeded");
        require(
            _giveawayClaimed[msg.sender] + _amount <= giveawayAmountLimit,  "Mint limit exceeded");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Max supply exceeded"
        );
             
        _giveawayClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {
        require(publicM,                        "PublicSale is OFF");
        require(!paused, "Contract is paused");
        require(_amount > 0, "zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "Not enough ethers sent"
        );
        
        
        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
    
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }


    //Owner minting function
     function ownerMinting(uint256 _amount) public onlyOwner {
    {
        require(
            _amount <= ownerAmountLimit,      "Mint limit exceeded");
        require(
            _ownerClaimed[msg.sender] + _amount <= ownerAmountLimit,  "Mint limit exceeded");

        require(_amount > 0, "zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Max supply exceeded"
        );

        _ownerClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }
  }

    function withdraw() public onlyOwner {
    (bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{value: address(this).balance * 2 / 100}("");
    require(hs);
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}



/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


