// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Payment /*is Ownable ; 수정필요*/ {

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
        store_cookFinish,
        rider_assigned,
        rider_inDelivery,
        rider_deliveryComplete
    }

    //주문번호로 주문 조회
    mapping(uint => Order) searchOrder; //완료된 주문 제거?
    //배달원별 배달목록
    mapping(address => Order[3]) deliveryList;

    //가게 점주 입장 구조체
    struct Store {
        address storeWallet;
        Role role;
        // address NFT;//수정필요
    }

    //배달원 구조체
    struct Rider {
        address riderWallet;
        Role role;
        // address NFT;//수정필요
    }

    //역할
    enum Role{
        store,
        rider
    }

    //배달원 목록
    mapping(address => Rider) riders;
    //가게 점주 목록
    mapping(address => Store) stores;

// 정보등록 -----------------------------------------------------------------------
    //가게(점주) 회원가입
    function storeRegist() public  {
        stores[msg.sender] = Store(msg.sender, Role.store);
    }
    //배달원 회원가입
    function riderRegist() public {
        riders[msg.sender]= Rider(msg.sender, Role.rider);
    }

// 결제 ------------------------------------------------------------------------------

    //고객이 주문하고 돈을 보냄
    function ordering(uint _orderID, address _sWallet, uint _foodPrice, uint _cDeliveryFee, uint _sDeliveryFee, uint _deliveryTip) public payable{
        require(msg.value == (_foodPrice + _cDeliveryFee + _deliveryTip));
        searchOrder[_orderID] = Order( _orderID, msg.sender, _sWallet, address(0) ,_foodPrice, _cDeliveryFee, _sDeliveryFee, _deliveryTip, orderState.order);
    }

    //가게 : 주문 수락시 배달비 지불 / 거절시 지불 안됨
    function storeAccept_Decline(uint _orderID, bool) public payable {
        require(riders[msg.sender].role == Role.store);
        require(msg.sender ==  searchOrder[_orderID].sWallet, "You can't access this order");
        require(searchOrder[_orderID].status == orderState.order, "You can't access this order");
        // require(/*NFT사용조건문*/,"You shound buy NFT"?); //수정 필요
        if(true){
            searchOrder[_orderID].status = orderState.store_accept;        
            require(msg.value == searchOrder[_orderID].sDeliveryFee, "You should pay DeliveryFee");
        }else{
            searchOrder[_orderID].status = orderState.store_decline;      
        }
    }

    //가게 음식조리완료 : 고객이 지불한 돈 받음
    function cookFinish(uint _orderID) public payable {
        require(msg.sender == searchOrder[_orderID].sWallet && searchOrder[_orderID].status == orderState.order, "You can't access this order");
        searchOrder[_orderID].status = orderState.store_cookFinish;
        payable (searchOrder[_orderID].sWallet).transfer(searchOrder[_orderID].foodPrice); //수수료 부과 필요
    }

    //배달원 지정
    function getDelivery(uint _orderID) public {
        require(riders[msg.sender].role == Role.rider);                         //배달기사 회원가입여부 확인
        require(searchOrder[_orderID].rWallet ==  address(0));                  //배달기사 지정 안된 상태인지 확인
        require(searchOrder[_orderID].status == orderState.store_accept);       //가게가 주문 받은 상태인지 확인
        // require( /*&&NFT확인*/);

        searchOrder[_orderID].rWallet = msg.sender;
        searchOrder[_orderID].status = orderState.rider_assigned;
        deliveryList[msg.sender][0] = searchOrder[_orderID]; //정적배열 수정필요
    }

    //배달시작  //제거 고민 중
    function setInDelivery(uint _orderID)public{
        require(searchOrder[_orderID].rWallet == msg.sender);
        require(searchOrder[_orderID].status == orderState.store_cookFinish);
        searchOrder[_orderID].status = orderState.rider_inDelivery;
    }

    //배달이 완료 : 배달비 수령
    function setDeliveryDone(uint _orderID) public {
        require(searchOrder[_orderID].rWallet == msg.sender && searchOrder[_orderID].status == orderState.rider_inDelivery);
        uint totalFee = searchOrder[_orderID].cDeliveryFee + searchOrder[_orderID].sDeliveryFee + searchOrder[_orderID].deliveryTip;
        payable(msg.sender).transfer(totalFee);
        
        //deliveryList[msg.sender][0] = searchOrder[_orderID];//배달 완료된 항목은 배달리스트에서 제거
    }

    //컨트랙트 돈 인출 //ownable 상속 후 수정
    function withdraw(uint _money) public{
        uint possible = address(this).balance -0/*출금불가한 금액*/;
        require (msg.sender == owner && possible >0);
        payable(owner).transfer(_money);
    }
}
