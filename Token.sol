// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/*
- 토큰 구매 (eth로 token 사기) ✅
- 구매가 일어날때 minting ✅
- token으로 음식 결제하기 (고객 -> 컨트랙트 : token // 컨트랙트 -> 주인 : ether) ✅ 
- 토큰으로 거래시 결제한 금액의 1% 리워드 ✅
- 토큰 가격은 1 BB = 1000원 or 1 BB = 1원 ; (decimals설정)
*/

contract BBlock is ERC20("BaeBlock","BB"){
    uint foodPrice = 12000 ; // 추후 상속받아 사용
    uint tokenPrice = 453012905708 wei ; //토큰 가격은 추후 수정(eth-krw api로 가격 받아옴) ; Open Exchange Rates", "ExchangeRate-API", "CurrencyLayer", "Alpha Vantage"
    uint public a = 4530129057079956 wei; // 1만원
    
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
        require(tokenAmount <= foodPrice);
        _transfer(msg.sender, address(this), tokenAmount);
        Reward(tokenAmount); //배달 완료되면 실행되도록 수정 필요
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

    //mint(1) = 1토큰
    function decimals() public pure override returns (uint8) {
        return 0;
    }
    
    receive() external payable{} //그러면 안되지만 잔고가 부족한 경우 받을 수 있게
}
