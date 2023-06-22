// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Payment {
// 변수선언 -----------------------------------------------------------------------
    address public owner;
    //컨트랙트 주인설정
    constructor(){
        owner = msg.sender;
    }

    //주문 구조체
    struct Order {
        uint orderID;
        address cWallet;
        address sWallet;
        address rWallet;
        uint foodPrice;
        uint cDeliveryFee;
        uint sDeliveryFee;
        uint deliveryTip;
        orderState status;
    }

    //주문상태
    enum orderState{
        order,
        store_accept,
        store_decline,
        // store_cookFinish,
        rider_assigned,
        rider_inDelivery,
        rider_deliveryComplete
    }

    //주문번호로 주문 조회
    mapping(uint => Order) searchOrder;
    //배달원별 배달목록
    mapping(address => Order[]) deliveryList;

    //가게 점주 입장 구조체
    struct Store_own {
        address storeWallet;
        address NFT;//?
    }

    //배달원 구조체
    struct Rider {
        address riderWallet;
        address NFT;//?
    }


// 결제 ------------------------------------------------------------------------------

    //고객이 주문하고 돈을 보냄
    function ordering(uint _orderID, address _sWallet, /*address _rWallet,*/ uint _foodPrice, uint _cDeliveryFee, uint _sDeliveryFee, uint _deliveryTip) public payable{
        require(msg.value == (_foodPrice + _cDeliveryFee + _deliveryTip));
        searchOrder[_orderID] = Order( _orderID, msg.sender, _sWallet, msg.sender,_foodPrice, _cDeliveryFee, _sDeliveryFee, _deliveryTip, orderState.order);
    }

    //가게 : 주문 수락시 배달비 지불 / 거절시 지불 안됨
    function storePay(uint _orderID, bool) public payable {
        require(msg.sender ==  searchOrder[_orderID].sWallet && searchOrder[_orderID].status == orderState.order, "You can't access this order");
        // require(/*NFT기간?횟수?*/,"You shound buy NFT"?);
        if(true){
            searchOrder[_orderID].status = orderState.store_accept;
            require(msg.value == searchOrder[_orderID].sDeliveryFee, "You should pay DeliveryFee");
        }else{
            searchOrder[_orderID].status = orderState.store_decline;
        }
    }

// 배달원 지정하는 부분 []로 만들어서 공동배달 관리 가능한 시스템으로 수정 중-----------
    //배달원지정
    function getDelivery(uint _orderID) public {
        require(searchOrder[_orderID].rWallet == searchOrder[_orderID].cWallet && searchOrder[_orderID].status == orderState.store_accept /*&&NFT확인*/);
        searchOrder[_orderID].rWallet = msg.sender;
        searchOrder[_orderID].status = orderState.rider_assigned;
        deliveryList[msg.sender].push(searchOrder[_orderID]); //정적배열로 바꾸기
    }

    //배달시작
    function setInDelivery(uint _orderID)public{
        require(searchOrder[_orderID].rWallet == msg.sender);
        // deliveryList[msg.sender].status
    }

    //배달이 완료되면 배달원/ 가게에게 돈이 전달
    function setDeliveryDone(uint _orderID) public {
        require(searchOrder[_orderID].rWallet == msg.sender && searchOrder[_orderID].status == orderState.rider_inDelivery);
        uint totalFee = searchOrder[_orderID].cDeliveryFee + searchOrder[_orderID].sDeliveryFee + searchOrder[_orderID].deliveryTip;
        payable(msg.sender).transfer(totalFee);
        payable (searchOrder[_orderID].sWallet).transfer(searchOrder[_orderID].foodPrice);

    }
//---------------------------------------------------------------------------------
    //컨트랙트 돈 인출
    function withdraw(uint _money) public{
        uint possible = address(this).balance -0/*출금불가한 금액*/;
        require (msg.sender == owner && possible >0);
        payable(owner).transfer(_money);
    }
}
