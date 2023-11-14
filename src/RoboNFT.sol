// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RoboNFT is ERC721{
    //鑄造價格
    uint256 public immutable mintPrice;
    //紀錄發行總發總數
    uint256 public totalSupply;
    //最大發行總數
    uint256 public immutable maxSupply;
    //每個錢包可以鑄造數
    uint256 public immutable maxPerWallet;
    //是否開始鑄造
    bool public isPublicMintEnabled = false;
    //是否開起盲盒
    bool public isFlipRevealed = false;
    //圖片的ipfs
    string internal baseTokenUri;
    //盲盒的ipfs
    string internal notRevealedUri;
    //紀錄每個錢包鑄造量
    mapping(address => uint256) public walletMints;
    //擁有者地址
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() payable ERC721('Robo', 'RP'){
        mintPrice = 0.02 ether;
        totalSupply = 0;
        maxSupply = 12;
        maxPerWallet = 3;
        owner = msg.sender;
    }

    //設置是否可開始mint
    function setIsPublicMintEnabled()external onlyOwner{
        isPublicMintEnabled = true;
    }
    //設置盲盒開啟
    function setFlipReveal() external onlyOwner {
        isFlipRevealed = true;
    }
    //設置盲盒URI
    function setNotRevealedURI(string memory notRevealedUri_) external onlyOwner {
        notRevealedUri = notRevealedUri_;
    }
    //設置URI
    function setBaseTokenUri(string memory baseTokenUri_) external onlyOwner{
        baseTokenUri = baseTokenUri_;
    }
    //覆蓋原先ERC721的URI
    function tokenURI(uint256 tokenId_) public view override returns(string memory){
        require(tokenId_ <= totalSupply && tokenId_ > 0, 'Token does not exist!');
        if (isFlipRevealed == true) {
            return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
        }else{
            return notRevealedUri;
        }
    }
    //提款
    function withdraw() external onlyOwner{
        (bool success, ) = payable(msg.sender).call{value:address(this).balance}('');
        require(success, 'withdraw failed');
    }
    //鑄造
    function mint(uint256 quantity_)public payable{
        require(isPublicMintEnabled, 'minting not enabled');
        require(msg.value == quantity_ * mintPrice, 'wrong mint value');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, 'exceed max wallet');

        for(uint256 i = 0; i < quantity_; i++){
            uint256 newtokenId = totalSupply +1;
            totalSupply++;
            _safeMint(msg.sender, newtokenId);
            walletMints[msg.sender]++;
        }
    }
}