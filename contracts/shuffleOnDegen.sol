// SPDX-License-Identifier: MIT
// ndgtlft etm.
pragma solidity ^0.8.24;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./base64.sol";

contract ShuffleOnDegen is ERC721Enumerable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string constant shuffleString = "DEGEN";
  uint256 public price;
  uint256 private _currentTokenId;
  bool public onSale;
  mapping(uint256 => uint32) private _tokenId2Date;
  mapping(uint32 => uint256[]) private _date2TokenIds;

  constructor() ERC721("shuffle on DEGEN", "SHUFFLE") Ownable(msg.sender) {
    _currentTokenId = 1;
    price = 0; //1DEGEN
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireOwned(tokenId);

    string memory svg1 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800"><path fill="#282C34" d="M0 0h800v800H0z"/><text x="50%" y="12%" fill="#fff" font-size="40" font-weight="300" text-anchor="middle" dominant-baseline="central">shuffle</text><text x="50%" y="20%" fill="#fff" font-size="35" font-weight="300" text-anchor="middle" dominant-baseline="central">on DEGEN</text><text x="50%" y="50%" fill="#38BDF8" font-size="120" font-weight="700" text-anchor="middle" dominant-baseline="central">';
    string memory resultText = getRandomPermutation();
    if (keccak256(abi.encodePacked(resultText)) == keccak256(abi.encodePacked("DEGEN"))){
      svg1 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800"><path fill="#282C34" d="M0 0h800v800H0z"/><text x="50%" y="12%" fill="#fff" font-size="40" font-weight="300" text-anchor="middle" dominant-baseline="central">shuffle</text><text x="50%" y="20%" fill="#fff" font-size="35" font-weight="300" text-anchor="middle" dominant-baseline="central">on DEGEN</text><text x="50%" y="50%" fill="#8B5CF5" font-size="120" font-weight="700" text-anchor="middle" dominant-baseline="central">';
    }
    string memory svg2 = '</text><text x="50%" y="80%" fill="#A3E635" font-size="35" font-weight="300" text-anchor="middle" dominant-baseline="central">';
    string memory dateText = getDateString(_tokenId2Date[tokenId]);
    string memory svg3 = '</text><text x="50%" y="85%" fill="#fff" font-size="35" font-weight="300" text-anchor="middle" dominant-baseline="central">minted #';
    string memory idText = Strings.toString(tokenId);
    string memory svg4 = '</text></svg>';
    string memory image = string(abi.encodePacked(svg1,resultText,svg2,dateText,svg3,idText,svg4));
    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "shuffle on ' , resultText , ' #', idText, '", "description": "The letters are shuffled and inscribed on-chain on DEGENchain.","attributes": [{"trait_type":"date","value":"' , dateText , '"},{"trait_type":"result","value":"' , resultText , '"}],"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}'))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function getDate(uint256 _timestamp) internal pure returns (uint32) {
    int256 __days = int256(_timestamp / 86400); //日数計算
    int256 L = __days + 68569 + 2440588; //計算された日数に固定値を加算してジュリアン日付
    int256 N = 4 * L / 146097; //400年ごとの完全な周期数を計算
    L = L - (146097 * N + 3) / 4; //400年周期に含まれない日数を再計算
    int256 _year = 4000 * (L + 1) / 1461001; //残った日数から現在の年を計算
    L = L - 1461 * _year / 4 + 31; //年を考慮に入れた後の残りの日数を計算
    int256 _month = 80 * L / 2447; //残った日数から月を計算
    int256 _day = L - 2447 * _month / 80; //月を引いた後の日を計算
    L = _month / 11; //月の値を調整
    _month = _month + 2 - 12 * L; //月の値を調整
    _year = 100 * (N - 49) + _year + L; //400年周期とその他の計算から最終的な年を決定

    return uint32(uint256(_year * 10000 + _month * 100 + _day));
  }

  function getDateString(uint32 _date) internal pure returns (string memory) {
        uint256 _year = _date / 10000;
        uint256 _month = (_date % 10000) / 100;
        uint256 _day = _date % 100;

        string memory separate1 = ".";
        if(_month < 10)separate1 = ".0";
        string memory separate2 = ".";
        if(_day < 10)separate2 = ".0";

        return string(abi.encodePacked(Strings.toString(_year),separate1,Strings.toString(_month),separate2,Strings.toString(_day)));
    }

  function mint(int256 timezoneOffset) external payable nonReentrant {
    require( -23 <= timezoneOffset && timezoneOffset <= 23, "Invalid timezoneOffset");
    require( msg.value == price, "Invalid price");
    uint256 tokenId = _currentTokenId++;
    uint32 date = getDate(uint256(int256(block.timestamp) + timezoneOffset * int256(3600)));
    _tokenId2Date[tokenId] = date;
    _date2TokenIds[date].push(tokenId);
    _safeMint(msg.sender, tokenId);
  }

  function getMintedTokenIds(uint32 date) public view returns (uint256[] memory){
    return _date2TokenIds[date];
  }

  //shuffle
  function getRandomPermutation() private view returns (string memory) {
    uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender)));
    return shuffle(shuffleString, randomSeed);
  }

  function shuffle(string memory input, uint256 randomSeed) private pure returns (string memory) {
    bytes memory inputBytes = bytes(input);
    for (uint256 i = 0; i < inputBytes.length; i++) {
      uint256 j = i + uint256(keccak256(abi.encode(randomSeed, i))) % (inputBytes.length - i);
      bytes1 temp = inputBytes[i];
      inputBytes[i] = inputBytes[j];
      inputBytes[j] = temp;
    }
    return string(inputBytes);
  }

  //owner
  function setPrice(uint256 newPrice) external onlyOwner {
    price = newPrice;
  }

  function setOnSale(bool newState) external onlyOwner {
    onSale = newState;
  }

  function withdraw(address payable toAddress, uint256 amountWei) external onlyOwner {
    Address.sendValue(toAddress, amountWei);
  }

}