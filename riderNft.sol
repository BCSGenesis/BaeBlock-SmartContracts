// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract delivery is ERC1155Supply,Ownable {
    
    uint public cost = 1 ;                         //민팅 비용
    uint public maxSupply = 10000;                      //nft 공급량
    uint public nftPerAddressLimit = 1;                 //지갑당 nft 제한
    mapping(address => uint) public _balances;          //지갑주소당 토큰 아이디 저장
    mapping(uint => uint) private _mintCounts;          //민트 수
    using Counters for Counters.Counter;                //유틸 카운터
    Counters.Counter private _tokenIds; 
    uint ownerMintedCount;                              //지갑 민팅 횟수
    uint[] public DeliveryNft;                          //총 공급량 컨트롤하기위해 배열 선언
    
    
    mapping(uint => uint) private _burnTimestamps;   // 민팅 시 _burnTimestamps 매핑에 소각 시간을 저장. 
    uint private _burnDelay = 60 days;               // 소각 딜레이 
    
    mapping(address => uint) public addressMintedBalance; // 민팅횟수를 매핑에 저장.
  
    address ownerWallet;
    constructor() ERC1155 ("https://maroon-mysterious-halibut-244.mypinata.cloud/ipfs/QmbPYnKWCgbGPydScgsnRWCdArPsmewPx59xnd6YiK28q4/riderNft.json") {
        ownerWallet=msg.sender;
    }
      


    //라이더가 배달권 가지고 있는지 확인하는require함수(order Contract에서 배달선택할때)

    //nft market의 배달권 구매 버튼 누르면 실행
    function DeliveryMint(uint amount) public payable {
          ownerMintedCount = addressMintedBalance[msg.sender];                  //지갑당 민팅횟수를 확인
          require(DeliveryNft.length < 10000, "The number of members is full"); //총 공급량 확인
          require(ownerMintedCount < nftPerAddressLimit, "max NFT per address exceeded"); //소지 제한
          uint tokenId = _tokenIds.current()+1;                                 //토큰의 아이디 카운트
          require(msg.value >= (cost * amount), "insufficient funds");            //잔액 확인
          require(DeliveryNft.length + amount < maxSupply, "max NFT limit exceeded");      //민팅 제한
          _tokenIds.increment();                                                //위 조건 통과시 토큰 아이디 증가
          _mint(msg.sender, tokenId, amount, "");
          _burnTimestamps[tokenId] = block.timestamp + _burnDelay;              //민팅한 시간에 유효기간 더하기
          _balances[msg.sender] = tokenId;
           DeliveryNft.push(tokenId);
         for (uint i = 1; i <= amount; i++) {                                   //리콰이어 통과 후 민팅하고나면 addressMintedBalance에 지갑 별로 카운팅이 되며 카운트가 1 이상이면 추가로 민팅이 불가.
         addressMintedBalance[msg.sender]++;
         
         }
          
    }
   
    //라이더 마이페이지에 번 버튼 필요
    function burn(address _a,uint tokenId) external {
        require(_balances[_a] == tokenId, "You are not the Owner");                     // 주인 확인
        require(_burnTimestamps[tokenId] != 0, "Token does not exist or already burned");       // 생성된 토큰인지 확인
        require(block.timestamp >= _burnTimestamps[tokenId], "Burn delay has not passed yet");  // 시간 확인
        _burn(msg.sender, tokenId, balanceOf(_a, tokenId));
        _burnTimestamps[tokenId] = 0;
         //리콰이어 통과 후 민팅하고나면 addressMintedBalance에 지갑 별로 카운팅이 되며 카운트가 1 이상이면 추가로 민팅이 불가.
        addressMintedBalance[_a]--;
        DeliveryNft.pop();
    }

    //함수 실행시킨 라이더가 가지고 있는 토큰의 타임스탬프가 몇인지
    function getRiderNftTime(address _a)external  view returns(uint){
        return _burnTimestamps[_balances[_a]];
    }
    function getRiderTokenId(address _a) external view returns (uint) {
        return _balances[_a];
    }
    
   
  
     //-------------------------------------------------------------테스트----------------------------------------------------//
     
        function setBurnDelay(uint tokenId) external onlyOwner {
        _burnTimestamps[tokenId] = block.timestamp - 70 days;
    }
        function getMintCount(uint tokenId) external view returns (uint) {
        return _mintCounts[tokenId];
    }
        function getBurnTimestamp(uint tokenId) external view returns (uint) {
        return _burnTimestamps[tokenId];
    }
        function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }
        function setBalance(address account, uint balance) external {
        _balances[account] = balance;
    }
        // contract가 _to에게 _amount만큼 보냄
        function transferTo(address payable _to, uint _amount) public {
        
        _to.transfer(_amount);
    }

    function balan(address) public view returns(uint) {
       return  _balances[msg.sender];
    }

    function getLength() public view returns(uint) {
        return DeliveryNft.length; //배열이름.길이
    }
    function getArray() public view returns(uint[] memory) {
        return DeliveryNft;
    }

    function withdrawal( uint _amount) public {
        require(ownerWallet==msg.sender,"you are not owner");
        payable (ownerWallet).transfer(_amount);
    }


}
     //-------------------------------------------------------------테스트----------------------------------------------------//

/* 스토어 nft 코드 진행
     배달원 nft와 거의 흡사한 진행이지만 무료 사용 기간이 있는 nft와 유료로 사용하는 nft를 구분해주어야 하기때문에 storeMint 함수에 if문을 사용해 무료nft,
     유료nft 민트를 구현함.
*/