// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract store is ERC1155 {

    uint public nftPerAddressLimit = 1; 
    uint ownerMintedCount;  
    uint public cost = 3000000000000000 ; 
    uint firstMint = 0;
    mapping(address => uint) public _balances;          
    mapping(uint => uint) private _mintCounts; 
    using Counters for Counters.Counter;                
    Counters.Counter private _tokenIds; 
    mapping(uint => uint) private _burnTimestamps; 
    uint private _burnDelay = 30 days; 
    mapping(address => uint) public addressMintedBalance; 
    mapping(address => uint) public firstMinting;
    
    
    address ownerWallet;
    constructor () ERC1155 ("https://maroon-mysterious-halibut-244.mypinata.cloud/ipfs/Qmdbz8XA1vzSTqdkp3TpoDFg754JMg8nHWMKGGrAPPc1fL/storeNft.json") {
      ownerWallet= msg.sender;
    }


    //스토어 회원가입 등록버튼 누르면 실행
    function storeMint() public payable returns(string memory) {
      ownerMintedCount = addressMintedBalance[msg.sender];
      require(ownerMintedCount < nftPerAddressLimit, "max NFT per address exceeded"); //소지 제한
      firstMint = firstMinting[msg.sender];
      uint tokenId = _tokenIds.current()+1; 
      if(firstMint < 1) {
          _tokenIds.increment();                                                //위 조건 통과시 토큰 아이디 증가
          _mint(msg.sender, tokenId, 1, "");
          _burnTimestamps[tokenId] = block.timestamp + _burnDelay;
          _balances[msg.sender] = tokenId;
          addressMintedBalance[msg.sender]++;
          firstMinting[msg.sender]++;  // 소각때 지워지면 안됨
          return "firstMint";
          } else {

              require(msg.value >= cost * 1, "insufficient funds");  
              _tokenIds.increment();
              _mint(msg.sender, tokenId, 1, "");
              _burnTimestamps[tokenId] = block.timestamp + _burnDelay;
              _balances[msg.sender] = tokenId;
              return "secondMint";
          }
      }

      function getMappingAccount(address _a) external view returns (uint){
    return _burnTimestamps[_balances[_a]];
}
      //함수 실행시킨 스토어가 가지고 있는 토큰의 타임스탬프가 몇인지
      function getStoreNftTime(address _a)external view returns(uint){
        return _burnTimestamps[_balances[_a]];
      }

      
      //스토어 마이페이지에 burn버튼 필요
     function storeBurn(address _msgSender,uint tokenId) external {
         
        require(_balances[_msgSender] == tokenId, "You are not the Owner");                     // 주인 확인
        require(_burnTimestamps[tokenId] != 0, "Token does not exist or already burned");       // 생성된 토큰인지 확인
        require(block.timestamp >= _burnTimestamps[tokenId], "Burn delay has not passed yet");  // 시간 확인
        _burn(_msgSender, tokenId, balanceOf(_msgSender, tokenId));
        _burnTimestamps[tokenId] = 0;
        addressMintedBalance[_msgSender]--; 
     }

     function getStoreTokenId(address _a) external view returns (uint) {
        return _balances[_a];
    }

  function withdrawal( uint _amount) public {
        require(ownerWallet==msg.sender,"you are not owner");
        payable (ownerWallet).transfer(_amount);
    }




    }