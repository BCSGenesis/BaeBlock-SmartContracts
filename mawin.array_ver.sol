// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Payment {

    address public owner;

    constructor(){
        owner=msg.sender;
    }

    //고객 구조체
    struct Customer {
        address  customerWallet;
        string customerNick;
        string customerAddress;
        Basket basket;
        Order goingOrder;
        Order[] pastOrderList;
    }
    //가게 점주 입장 구조체
    struct Store_own {
        address  storeWallet;
        string storeName;
        string storeAddress;
        uint monthOrderCount;
        uint monthPeriod;
        Menu[] menuList;
        Order[] orderList;
    }


    //가게 고객 입장 구조체
    struct Store_cus {
        address  storeWallet;
        string storeName;
        string storeAddress;
        Menu[] menuList;
    }
    //배달원 구조체
    struct Rider {
        address  riderWallet;
        string deliveryType;
        string deliveryZone;
        Order[] orders;
    }
    //메뉴 구조체
    struct Menu {
        string name;
        uint price;
        uint count;
    }
    //장바구니 구조체
    struct Basket {
        address customerAddr;
        address storeAddr;
        string customerAddress;
        string storeAddress;
        Menu[] menuNames;
        uint foodPrice;
        uint deliveryFee;
    }
    //주문 구조체
    struct Order {
        uint orderID;
        address customerAddr;
        address storeAddr;
        address riderAddr;
        string customerAddress;
        string storeAddress;
        Menu[] menuName;
        uint foodPrice;
        uint deliveryFee;
        uint deliveryTip;
        storeState storeStatus;
        riderState riderStatus;
    }
    //주문에 대한 가게 반응 상태
    enum storeState {decline, accept,cookFinish, isPicked,notyetChoice,checkMoney}
    //주문에 대한 배달원 반응 상태
    enum riderState {notSelected, inDelivery, isPicked, deliveryComplete,checkMoney}

    //고객들 저장된 맵핑
    mapping(address => Customer) customers;
    //가게들 저장된 배열(고객이 쇼핑하는 입장)
    Store_cus[] stores_customer;
    //가게들 저장된 배열(가게주인 관리하는 입장)
    mapping(address=>Store_own) stores_owner;
    //배달원들 저장된 맵핑
    mapping(address => Rider) riders;
    //배달대기목록
    Order[] deliveryWaitingList;

    //주문고유번호
    uint public orderNum;

    //가게------------------------------------------------------------------------------------------------

    //가게 가입 기능
    function storeRegist(string memory _storeName,string memory _storeAddress) public {
        //stores_customer 배열에 가게 추가하기
        Store_cus storage newStore_cus = stores_customer.push();
        newStore_cus.storeWallet=msg.sender;
        newStore_cus.storeName=_storeName;
        newStore_cus.storeAddress=_storeAddress;
        //stores_owner 맵핑에 가게 추가하기
        Store_own storage newStore_own=stores_owner[msg.sender];
        newStore_own.storeWallet= msg.sender;
        newStore_own.storeName=_storeName;
        newStore_own.storeAddress=_storeAddress;
        newStore_own.monthOrderCount=0;
        newStore_own.monthPeriod=block.timestamp+30 days;

    }

    //가게 메뉴 등록 기능
    function storeMenuRegist(string memory _menuName,uint _price)public{
        //stores_customer 배열의 Menu[]에 메뉴 추가하기
        for(uint i=0;i<stores_customer.length;i++){
            if(stores_customer[i].storeWallet==msg.sender){
                stores_customer[i].menuList.push(Menu(_menuName,_price,0));
            }
        }
        //stores_owner 매핑의 Menu[]에 메뉴 추가하기
        stores_owner[msg.sender].menuList.push(Menu(_menuName,_price,0));
    }


    //가게의 주문 수락
    function storeAccept(uint _orderId) public {
        for(uint i=0;i<stores_owner[msg.sender].orderList.length;i++){
            if(stores_owner[msg.sender].orderList[i].orderID==_orderId){
                //고객의 order상태 변경
                customers[stores_owner[msg.sender].orderList[i].customerAddr].goingOrder.storeStatus=storeState.accept;
                //가게(stores_owner)의 order상태 변경
                stores_owner[msg.sender].orderList[i].storeStatus=storeState.accept;
            }
        }
    }

    //가게의 주문 거절
    function storeDecline(uint _orderId) public {
        for(uint i=0;i<stores_owner[msg.sender].orderList.length;i++){
            //고객의 order상태 변경
            if(customers[stores_owner[msg.sender].orderList[i].customerAddr].goingOrder.orderID==_orderId){
                customers[stores_owner[msg.sender].orderList[i].customerAddr].goingOrder.storeStatus=storeState.decline;
            }
            //가게(stores_owner)의 order상태 변경
            if(stores_owner[msg.sender].orderList[i].orderID==_orderId){
                stores_owner[msg.sender].orderList[i].storeStatus=storeState.decline;
            }
        }
        //배달대기리스트에서 주문건 삭제
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].orderID==_orderId){
                delete deliveryWaitingList[i];
            }
        }
        //가게 매핑에서 지우기
        for(uint i=0;i<stores_owner[msg.sender].orderList.length;i++){
            if(stores_owner[msg.sender].orderList[i].orderID==_orderId){
               delete stores_owner[msg.sender].orderList[i];
            }
        }
    }

    //가게의 요리 완료
    function cookFinish(uint _orderId)public {
        
        for(uint i=0;i<stores_owner[msg.sender].orderList.length;i++){
            if(stores_owner[msg.sender].orderList[i].orderID==_orderId){
                //가게(stores_owner)의 order상태 변경
                stores_owner[msg.sender].orderList[i].storeStatus=storeState.cookFinish;
                //고객의 order상태 변경
                customers[stores_owner[msg.sender].orderList[i].customerAddr].goingOrder.storeStatus=storeState.cookFinish;
                
                //주문 완료 건수 추가
                stores_owner[msg.sender].monthOrderCount+=1;
                
                if(stores_owner[msg.sender].monthPeriod<block.timestamp){
                    stores_owner[msg.sender].monthOrderCount = 0;
                }


                //음식값 받기(월 몇건이상 조건 추가)
                if(stores_owner[msg.sender].monthOrderCount>3){
                    payable (stores_owner[msg.sender].orderList[i].storeAddr).transfer((stores_owner[msg.sender].orderList[i].foodPrice)*0.98 ether);
                }else{
                    payable (stores_owner[msg.sender].orderList[i].storeAddr).transfer((stores_owner[msg.sender].orderList[i].foodPrice)*1 ether);
                }
               
               

            }
        }                 
    }

    //가게의 주문 조회
    function myStoreOrder()public view returns(Order[] memory){
        return (stores_owner[msg.sender].orderList);
    }

    //고객--------------------------------------------------------------------------------------------

    //고객 회원가입 기능
    function customerRegist(string memory _customerNick,string memory _customerAddress) public {
        Customer storage newCustomer=customers[msg.sender];
        newCustomer.customerWallet=msg.sender;
        newCustomer.customerNick=_customerNick;
        newCustomer.customerAddress=_customerAddress;
    }

    //장바구니에 메뉴 담기
    function addMenuToBusket(string memory _storeName,string memory _foodName,uint _count)public {
        customers[msg.sender].basket.customerAddr=msg.sender;       
        customers[msg.sender].basket.customerAddress=customers[msg.sender].customerAddress;
        for(uint i=0;i<stores_customer.length;i++){
            if(keccak256(abi.encodePacked(stores_customer[i].storeName)) == keccak256(abi.encodePacked(_storeName))){
                customers[msg.sender].basket.storeAddr=stores_customer[i].storeWallet;
                customers[msg.sender].basket.storeAddress = stores_customer[i].storeAddress;
                for(uint j=0;j<stores_customer[i].menuList.length;j++){
                    if(keccak256(abi.encodePacked(stores_customer[i].menuList[j].name))==keccak256(abi.encodePacked(_foodName))){
                        customers[msg.sender].basket.menuNames.push(Menu(stores_customer[i].menuList[j].name,stores_customer[i].menuList[j].price,_count));
                    }                    
                }
            }
        }       
        customers[msg.sender].basket.foodPrice=menuTotalPriceForBasket();
        customers[msg.sender].basket.deliveryFee=0;   
    }

    //메뉴 총 가격 계산하기
    function menuTotalPriceForBasket()public view returns(uint){
        uint totalPrice;
        uint menuLength = customers[msg.sender].basket.menuNames.length;
        for (uint i = 0; i < menuLength; i++) {
            totalPrice += customers[msg.sender].basket.menuNames[i].price*customers[msg.sender].basket.menuNames[i].count;
        }
        return totalPrice;
    }

    //주문하기
    function ordering(uint _deliveryTip) public {
        //고객정보에 주문 추가
        orderNum++;
        Order storage newOrder = customers[msg.sender].goingOrder;
        newOrder.orderID= orderNum;
        newOrder.customerAddr=msg.sender;
        newOrder.storeAddr=customers[msg.sender].basket.storeAddr;
        newOrder.customerAddress=customers[msg.sender].basket.customerAddress;
        newOrder.storeAddress=customers[msg.sender].basket.storeAddress;
        for(uint i=0;i<customers[msg.sender].basket.menuNames.length;i++){
            newOrder.menuName.push(customers[msg.sender].basket.menuNames[i]);
        }
        newOrder.foodPrice=menuTotalPriceForBasket();
        newOrder.deliveryFee=0;
        newOrder.deliveryTip=_deliveryTip;
        newOrder.storeStatus=storeState.notyetChoice;
        newOrder.riderStatus=riderState.notSelected; 
        //가게(가게맵핑)에 주문 추가
        Order storage newOrder2 = stores_owner[customers[msg.sender].basket.storeAddr].orderList.push();
        newOrder2.orderID= customers[msg.sender].goingOrder.orderID;
        newOrder2.customerAddr=msg.sender;
        newOrder2.storeAddr=customers[msg.sender].goingOrder.storeAddr;
        newOrder2.customerAddress=customers[msg.sender].goingOrder.customerAddress;
        newOrder2.storeAddress=customers[msg.sender].goingOrder.storeAddress;
        for(uint i=0;i<customers[msg.sender].goingOrder.menuName.length;i++){
            newOrder2.menuName.push(customers[msg.sender].goingOrder.menuName[i]);
        }
        newOrder2.foodPrice=menuTotalPriceForBasket();
        newOrder2.deliveryFee=0;
        newOrder2.deliveryTip=_deliveryTip;
        newOrder2.storeStatus=storeState.notyetChoice;
        newOrder2.riderStatus=riderState.notSelected;
        //배달 목록에 등록
        Order storage newOrder3 = deliveryWaitingList.push();
        newOrder3.orderID= customers[msg.sender].goingOrder.orderID;
        newOrder3.customerAddr=msg.sender;
        newOrder3.storeAddr=customers[msg.sender].goingOrder.storeAddr;
        newOrder3.customerAddress=customers[msg.sender].goingOrder.customerAddress;
        newOrder3.storeAddress=customers[msg.sender].goingOrder.storeAddress;
        for(uint i=0;i<customers[msg.sender].goingOrder.menuName.length;i++){
            newOrder3.menuName.push(customers[msg.sender].goingOrder.menuName[i]);
        }
        newOrder3.foodPrice=menuTotalPriceForBasket();
        newOrder3.deliveryFee=0;
        newOrder3.deliveryTip=_deliveryTip;
        newOrder3.storeStatus=storeState.notyetChoice;
        newOrder3.riderStatus=riderState.notSelected; 
    }

    //메뉴 총 가격 계산하기2
    function menuTotalPriceForOrder()public view returns(uint){
        uint totalPrice;
        uint menuLength = customers[msg.sender].goingOrder.menuName.length;
        for (uint i = 0; i < menuLength; i++) {
            totalPrice += customers[msg.sender].goingOrder.menuName[i].price*customers[msg.sender].goingOrder.menuName[i].count;
        }
        return totalPrice;
    }

    //주문건 조건이 맞을경우, 컨트랙트에 돈 지불
    function payment()public payable {
        //고객 주문건이 가게는수락, 라이더는 배달하기로 선택한 상태
        require(customers[msg.sender].goingOrder.storeStatus==storeState.accept &&
                customers[msg.sender].goingOrder.riderStatus==riderState.isPicked);
        //컨트랙트에 가격지불
        require(
            msg.value==(customers[msg.sender].goingOrder.foodPrice+
            customers[msg.sender].goingOrder.deliveryFee+
            customers[msg.sender].goingOrder.deliveryTip)*1 ether
            );
        //가게(stores_owner)의 order상태 변경
        for(uint i=0;i<stores_owner[customers[msg.sender].goingOrder.storeAddr].orderList.length;i++){
            if(stores_owner[customers[msg.sender].goingOrder.storeAddr].orderList[i].orderID==customers[msg.sender].goingOrder.orderID){
                stores_owner[customers[msg.sender].goingOrder.storeAddr].orderList[i].riderStatus = riderState.checkMoney;
            }
        }
     
        //고객의 order상태 변경
        customers[msg.sender].goingOrder.storeStatus==storeState.checkMoney;
        //배달원 주문건의 상태 변경
        for(uint i=0;i<riders[customers[msg.sender].goingOrder.riderAddr].orders.length;i++){
            if(riders[customers[msg.sender].goingOrder.riderAddr].orders[i].orderID==customers[msg.sender].goingOrder.orderID){
                riders[customers[msg.sender].goingOrder.riderAddr].orders[i].riderStatus = riderState.checkMoney;
            }
        }
        //배달건 주문상태 변경
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].orderID==customers[msg.sender].goingOrder.orderID){
                deliveryWaitingList[i].storeStatus==storeState.checkMoney;
                deliveryWaitingList[i].riderStatus = riderState.checkMoney;
            }
        }
    }

    function myCustomerGoingOrder()public view returns(Order memory){
        return customers[msg.sender].goingOrder;
    }
    function myCustomerPastOrder()public view returns(Order[] memory){
        return customers[msg.sender].pastOrderList;
    }

    //라이더---------------------------------------------------------------------------------------------

    //라이더 회원가입 기능
    function riderRegist(string memory _deliveryType,string memory _deliveryZone) public{
        Rider storage newRider = riders[msg.sender];
        newRider.riderWallet = msg.sender;
        newRider.deliveryType = _deliveryType;
        newRider.deliveryZone = _deliveryZone;
    }

    //라이더의 배달 선택
    function riderPickOrder(uint _orderId)public {
        //라이더의 배달목록에 추가
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].orderID==_orderId){
                //고객 주문건에 라이더 등록
                customers[deliveryWaitingList[i].customerAddr].goingOrder.riderAddr = msg.sender;
                //가게 주문건에 라이더 등록
                for(uint j=0;j<stores_owner[deliveryWaitingList[i].storeAddr].orderList.length;j++){
                    if(stores_owner[deliveryWaitingList[i].storeAddr].orderList[j].orderID==_orderId){
                        stores_owner[deliveryWaitingList[i].storeAddr].orderList[j].riderAddr = msg.sender;
                    }
                }
                //배달 주문건에 라이더 등록
                deliveryWaitingList[i].riderAddr = msg.sender; 
            }
        }
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].orderID==_orderId){
                //라이더의 배달목록에 추가
                Order storage newOrder = riders[msg.sender].orders.push();
                newOrder.orderID= deliveryWaitingList[i].orderID;
                newOrder.customerAddr=deliveryWaitingList[i].customerAddr;
                newOrder.storeAddr=deliveryWaitingList[i].storeAddr;
                newOrder.riderAddr=deliveryWaitingList[i].riderAddr;
                newOrder.customerAddress=deliveryWaitingList[i].customerAddress;
                newOrder.storeAddress=deliveryWaitingList[i].storeAddress;
                for(uint j=0;j<customers[deliveryWaitingList[i].customerAddr].goingOrder.menuName.length;j++){
                    newOrder.menuName.push(customers[deliveryWaitingList[i].customerAddr].goingOrder.menuName[j]);
                }
                newOrder.foodPrice=deliveryWaitingList[i].foodPrice;
                newOrder.deliveryFee=deliveryWaitingList[i].deliveryFee;
                newOrder.deliveryTip=deliveryWaitingList[i].deliveryTip;
                newOrder.storeStatus=deliveryWaitingList[i].storeStatus;
                newOrder.riderStatus=riderState.isPicked;
                //배달 대기목록의 주문건 상태 수정
                deliveryWaitingList[i].storeStatus=storeState.isPicked;
                deliveryWaitingList[i].riderStatus=riderState.isPicked;

                
                //고객의 주문건 상태 수정
                // customers[deliveryWaitingList[i].customerAddr].goingOrder.storeStatus=storeState.isPicked;
                customers[deliveryWaitingList[i].customerAddr].goingOrder.riderStatus=riderState.isPicked;
                //가게의 주문건 상태 수정
                for(uint k=0;k<deliveryWaitingList.length;k++){
                    if(stores_owner[deliveryWaitingList[i].storeAddr].orderList[k].orderID==_orderId){
                        //stores_owner[deliveryWaitingList[i].storeAddr].orderList[k].storeStatus=storeState.isPicked;
                        stores_owner[deliveryWaitingList[i].storeAddr].orderList[k].riderStatus=riderState.isPicked;
                    }
                }  
            }
        }
    }

    //배달 시작 기능
    function riderStartDelivery(uint _orderId)public {
        for(uint i=0;i<riders[msg.sender].orders.length;i++){
            if(riders[msg.sender].orders[i].orderID==_orderId){
                //돈 받아야 배달 출발조건
                if(riders[msg.sender].orders[i].riderStatus==riderState.checkMoney){
                    //배달기사 상태 진행중으로로
                    riders[msg.sender].orders[i].riderStatus=riderState.inDelivery;
                    //배달 대기목록의 배달 상태 진행중으로
                    for(uint j=0;j<deliveryWaitingList.length;j++){
                        if(deliveryWaitingList[j].orderID==_orderId){
                            deliveryWaitingList[j].riderStatus=riderState.inDelivery;
                        }
                    }
                    //고객 배달 상태 진행중으로
                    customers[riders[msg.sender].orders[i].customerAddr].goingOrder.riderStatus=riderState.inDelivery;
                    
                    //가게 주문문목록의 배달 상태 진행중으로
                    for(uint j=0;j<stores_owner[riders[msg.sender].orders[i].storeAddr].orderList.length;j++){
                        if(stores_owner[riders[msg.sender].orders[i].storeAddr].orderList[j].orderID==_orderId){
                            stores_owner[riders[msg.sender].orders[i].storeAddr].orderList[j].riderStatus=riderState.inDelivery;
                        }
                    }
                }
            }
        }
    }

    //배달 완료 기능
    function riderFinishDelivery(uint _orderId)public {
        for(uint i=0;i<riders[msg.sender].orders.length;i++){
            if(riders[msg.sender].orders[i].orderID==_orderId){
                //배달진행중이어야하는 조건
                if(riders[msg.sender].orders[i].riderStatus==riderState.inDelivery){
                    //라이더의 해당 주문 건 배달 완료
                    riders[msg.sender].orders[i].riderStatus=riderState.deliveryComplete;
                    //배달 대기목록의 배달 상태 완료로    
                    for(uint j=0;j<deliveryWaitingList.length;j++){
                        if(deliveryWaitingList[j].orderID==_orderId){
                            deliveryWaitingList[j].riderStatus=riderState.deliveryComplete;
                        }
                    }
                    //고객 배달 상태 진행중으로
                    customers[riders[msg.sender].orders[i].customerAddr].goingOrder.riderStatus=riderState.deliveryComplete;
                    
                    //가게 주문문목록의 배달 상태 진행중으로
                    for(uint j=0;j<stores_owner[riders[msg.sender].orders[i].storeAddr].orderList.length;j++){
                        if(stores_owner[riders[msg.sender].orders[i].storeAddr].orderList[j].orderID==_orderId){
                            stores_owner[riders[msg.sender].orders[i].storeAddr].orderList[j].riderStatus=riderState.deliveryComplete;
                        }
                    }


                    /*
                    //음식값 받기
                    payable (stores_owner[riders[msg.sender].orders[i].storeAddr].storeWallet).transfer((riders[msg.sender].orders[i].foodPrice)*1 ether);
                    
                    
                    //라이더 배달비 받기
                    payable (riders[msg.sender].riderWallet).transfer((riders[msg.sender].orders[i].deliveryFee+riders[msg.sender].orders[i].deliveryTip)*1 ether);
                    */

                    
                    //고객의 배달 과거목록에 추가
                    Order storage pastOrder = customers[riders[msg.sender].orders[i].customerAddr].pastOrderList.push();
                    pastOrder.orderID= customers[riders[msg.sender].orders[i].customerAddr].goingOrder.orderID;
                    pastOrder.customerAddr=customers[riders[msg.sender].orders[i].customerAddr].goingOrder.customerAddr;

                    pastOrder.storeAddr=customers[riders[msg.sender].orders[i].customerAddr].goingOrder.storeAddr;
                    
                    pastOrder.customerAddress=customers[riders[msg.sender].orders[i].customerAddr].goingOrder.customerAddress;
                    pastOrder.storeAddress=customers[riders[msg.sender].orders[i].customerAddr].goingOrder.storeAddress;
                    for(uint k=0;k<customers[riders[msg.sender].orders[i].customerAddr].goingOrder.menuName.length;k++){
                        pastOrder.menuName.push(customers[riders[msg.sender].orders[i].customerAddr].goingOrder.menuName[k]);
                    }
                    
                    pastOrder.foodPrice=customers[riders[msg.sender].orders[i].customerAddr].goingOrder.foodPrice;
                    pastOrder.deliveryFee=customers[riders[msg.sender].orders[i].customerAddr].goingOrder.deliveryFee;
                    
                    pastOrder.deliveryTip=customers[riders[msg.sender].orders[i].customerAddr].goingOrder.deliveryTip;
                    pastOrder.storeStatus=customers[riders[msg.sender].orders[i].customerAddr].goingOrder.storeStatus;
                    
                    pastOrder.riderStatus=customers[riders[msg.sender].orders[i].customerAddr].goingOrder.riderStatus; 
                    
                    //고객의 goingOrder초기화
                    customers[msg.sender].goingOrder.orderID= 0;
                    customers[msg.sender].goingOrder.customerAddr=address(0);
                    customers[msg.sender].goingOrder.storeAddr=address(0);
                    customers[msg.sender].goingOrder.customerAddress="";
                    customers[msg.sender].goingOrder.storeAddress="";
                    
                    for(uint k=0; k < customers[riders[msg.sender].orders[i].customerAddr].goingOrder.menuName.length ; k++){
                        customers[riders[msg.sender].orders[i].customerAddr].goingOrder.menuName.pop();
                    }        
                    
                    customers[msg.sender].goingOrder.foodPrice=0;
                    customers[msg.sender].goingOrder.deliveryFee=0;
                    customers[msg.sender].goingOrder.deliveryTip=0;
                    customers[msg.sender].goingOrder.storeStatus=storeState.notyetChoice;
                    customers[msg.sender].goingOrder.riderStatus=riderState.notSelected; 

                    // //고객의 basket초기화
                    customers[riders[msg.sender].orders[i].customerAddr].basket.customerAddr=address(0);
                    customers[riders[msg.sender].orders[i].customerAddr].basket.storeAddr=address(0);
                    customers[riders[msg.sender].orders[i].customerAddr].basket.customerAddress="";
                    customers[riders[msg.sender].orders[i].customerAddr].basket.storeAddress="";
                    for(uint l=0;l<customers[riders[msg.sender].orders[i].customerAddr].basket.menuNames.length;l++){
                        customers[riders[msg.sender].orders[i].customerAddr].basket.menuNames.pop();
                    }
                    customers[riders[msg.sender].orders[i].customerAddr].basket.foodPrice=0;
                    customers[riders[msg.sender].orders[i].customerAddr].basket.deliveryFee=0;
                    
                }
            }
        }
    }

    //배달대기목록조회
    function deliverylistOrder()public view returns(Order[] memory){
        return deliveryWaitingList;
    }

    //라이더 자기 주문 조회
    function myRiderOrder()public view returns(Order[] memory){
        return riders[msg.sender].orders;
    }


    //관리자---------------------------------------------------------------------------------------------

    function withdraw(uint _amount)public {
        require(msg.sender == owner);
        payable (msg.sender).transfer(_amount * 1 ether);
    }

}
