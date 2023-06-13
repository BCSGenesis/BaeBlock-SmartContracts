// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

// 토큰 구매 가능
// 토큰 가격은 1 BBL = 1000원
// 최소 1천원 단위로 구매가능
// 토큰으로 거래시 1% 리워드
// 컨트랙트에 토큰을 쌓아두고 거래


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
