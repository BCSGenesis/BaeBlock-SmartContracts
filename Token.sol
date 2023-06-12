// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract BBlock is ERC20("BaeBlock","BB"){

    //발행량 정해야함 (계속 배포 가능하게? 한정된 수량? 운영을 어떻게 할지 구체적으로 구상필요)
    //발행된 토큰이 버튼 누른 사람의 지갑으로 들어감
    constructor(uint _totalSupply){
        _mint(msg.sender, _totalSupply);
    }
    
    //버튼 누른 사람의 잔고 조회
    function getBalance() public view returns(uint){
        return balanceOf(msg.sender);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
    
    //발행한 토큰이 스마트 컨트랙트에 저장
    function MintToken(uint a) public {
        _mint(address(this), a);
    }
    
    receive() external payable{}

}
