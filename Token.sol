// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

// 토큰 구매 가능
// 토큰으로 거래시 1% 리워드
// 토큰 가격은 1 BBL = 1000원
// 구매가 일어날때 minting

/*
eth로 token 사기 ✅
token으로 음식 결제하기 ✅
(고객 -> 컨트랙트
컨트랙트 -> 주인)
결제한 금액의 1% 리워드 ✅
*/

contract BBlock is ERC20("BaeBlock","BB"){
    
    uint tokenPrice = 10000000000 wei; //토큰 가격은 추후 수정
    
    function buyTokens() external payable{
        uint tokenAmount = msg.value/tokenPrice;
        require(tokenAmount > 0, "Insufficient payment"); //잔고 부족일 경우 반환

        if(balanceOf(address(this))>= tokenAmount){
            _transfer(address(this), msg.sender, tokenAmount);
        }else{
            _mint(msg.sender, tokenAmount);
        }
    }

    function payWithTokens(uint tokenAmount, address payable  _storeOwner) public payable {
        // require(tokenAmount < foodPrice);
        _transfer(msg.sender, address(this), tokenAmount);
        Reward(tokenAmount);
        // 가게 점주에게 알맞은 금액 전송()
        etherToStore(tokenAmount, _storeOwner);
    }
    
    //private 확인
    function etherToStore(uint tokenAmount, address payable _storeOwner) private {
        _storeOwner.transfer(tokenAmount * tokenPrice);
    }
   
    //토큰으로 거래시 1% 리워드 (private 확인)
    function Reward(uint _tokenAmount) private {
        uint rewardToken = _tokenAmount/100;
        if(balanceOf(address(this))>= rewardToken){
            _transfer(address(this), msg.sender, rewardToken);
        }else{
            _mint(msg.sender, rewardToken);
        }
    }

    //decimals확인 (표시가 E-3까지 가능한건지 1토큰이 0.001토큰으로 발행되는건지..)
    function decimals() public pure override returns (uint8) {
        return 3;
    }
    
    //receive() external payable{}

}
