// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

// 토큰 구매 가능
// 토큰으로 거래시 1% 리워드
// 토큰 가격은 1 BBL = 1000원
// 컨트랙트에 토큰을 쌓아두고 거래?? 

/* 질문
1. 토큰을 포인트 개념과 유사하게 사용하고 싶은데, 포인트의 경우 1p = 100원 이런식으로 고정되어있는데 토큰도 고정시켜도 되나요?
    eth로 토큰구매/ 1토큰 = 1000원 / eth-원화 계속 변동...  // 토큰 가격도 변동???? 토큰 거래가격이 변동되는거랑 처음 mint해서 사가는 가격은 별도??
    1-2) 가격 고정이 가능하다면 eth-원화 추적 api? 같은걸 사용해서 금액을 가지고 오면되는지?
2. 토큰 발행의 경우 구매가 일어날 경우 발행을 해서 사용하면 되는지? 미리 발행을 해둬야하는지? 
    constructor쓰는 이유는 그냥 초기에 주인이 토큰을 가지기 위함인지?
    총발행량은 ERC20 작성시 초기에 설정안해도 되는걸로 아는데 서비스를 사용할때 결국 정하고 시작해야하는지?
*/

contract BBlock is ERC20("BaeBlock","BB"){
    
    address private C_owner;

    //초기 오너설정 및 토큰 발행
    constructor(uint _initialSupply) {
        _mint(address(this), _initialSupply);
        C_owner = msg.sender;
    }

    //추가 토큰 발행 ; buyToken, getReward에 따라 자동으로 발행되도록 수정?
    function MintToken(uint _a) public {
        require(C_owner == msg.sender, "You can't mint Token");
        _mint(address(this), _a);
    } 

    //decimals기능 다시 찾아보기! (표시가 E-3까지 가능한건지 1토큰이 0.001토큰으로 발행되는건지..)
    function decimals() public pure override returns (uint8) {
        return 3;
    }
    
    receive() external payable{}

    //토큰으로 거래시 1% 리워드 ; internal? 
    // _amountBB :  거래시 지불한 토큰금액 
    function Reward(uint _amountBB) public {
        _transfer(address(this), msg.sender, _amountBB/100);
    }

    // 지불구조 미완성
    function buyToken(uint _amountKRW) public payable {
        require(balanceOf(msg.sender) > 0, "" ); //ether잔고 조회
        _transfer(address(this), msg.sender, _amountKRW/1000);
    }

}
