// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Payment {
    //고객 구조체
    struct Customer {
        address  customerWallet;
        string customerAddress;
        Busket busket;
        Order goingOrder;
    }
    //가게 점주 입장 구조체
    struct Store_own {
        address  storeWallet;
        string storeName;
        string storeAddress;
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
        Order[] orders;
    }
    //메뉴 구조체
    struct Menu {
        string name;
        uint price;
        uint count;
    }
    //장바구니 구조체체
    struct Busket {
        address customerAddr;
        address storeAddr;
        string customerAddress;
        string storeAddress;
        Menu[] menuName;
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
    enum riderState {selected,notSelected, inDelivery, isPicked, deliveryComplete}

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

    //고객 등록 기능
    function customerRegist(string memory _customerAddress) public view {
        Customer memory newCustomer = customers[msg.sender];
        newCustomer.customerWallet=msg.sender;
        newCustomer.customerAddress=_customerAddress;
        newCustomer.busket=Busket(msg.sender,address(0),"","",new Menu[](0),0,0);
        newCustomer.goingOrder=Order(0,address(0),address(0),address(0),"","", new Menu[](0),0,0,0,storeState.notyetChoice,riderState.notSelected);
    }

    //라이더 등록 기능
    function riderRegist() public view{       
        Rider memory newRider=riders[msg.sender];
        newRider.riderWallet=msg.sender;
        newRider.orders= new Order[](0);
    }

    //가게 등록 기능
    function storeRegist(string memory _storeName,string memory _storeAddress) public {
        //stores 고객 배열에 가게 추가하기
        Store_cus memory newStore_cus = stores_customer.push();
        newStore_cus.storeWallet=msg.sender;
        newStore_cus.storeName=_storeName;
        newStore_cus.storeAddress=_storeAddress;
        newStore_cus.menuList=new Menu[](0);

        //stores 점주 맵핑에 가게 추가하기
        Store_own memory newStore_own = stores_owner[msg.sender];
        newStore_own.storeWallet=msg.sender;
        newStore_own.storeName=_storeName;
        newStore_own.storeAddress=_storeAddress;
        newStore_own.menuList=new Menu[](0);
        newStore_own.orderList=new Order[](0);
    }

    //가게 메뉴 등록 기능
    function storeMenuRegist(string memory _menuName,uint _price)public{
        //stores 고객 배열의 Mene[]에 메뉴 추가하기
        for(uint i=0;i<stores_customer.length;i++){
            if(stores_customer[i].storeWallet==msg.sender){
                stores_customer[i].menuList.push(Menu(_menuName,_price,0));
            }
        }
        //stores 점주 배열의 Mene[]에 메뉴 추가하기
        stores_owner[msg.sender].menuList.push(Menu(_menuName,_price,0));
    }

    //장바구니에 메뉴 담기
    function addMenuToBusket(address _storeAddr,string memory _foodName)public {
        
        customers[msg.sender].busket.customerAddr=msg.sender;
        customers[msg.sender].busket.storeAddr=_storeAddr;
        customers[msg.sender].busket.customerAddress=customers[msg.sender].customerAddress;
        for(uint i=0;i<stores_customer.length;i++){
            if(stores_customer[i].storeWallet == _storeAddr){
                for(uint j=0;j<stores_customer[i].menuList.length;j++){
                    if(keccak256(abi.encodePacked(stores_customer[i].menuList[j].name))==keccak256(abi.encodePacked(_foodName))){
                        customers[msg.sender].busket.menuName.push(stores_customer[i].menuList[j]);
                    }
                }
            }
        }
        customers[msg.sender].busket.foodPrice=menuTotalPriceForBusket();
        customers[msg.sender].busket.deliveryFee=0;
    }

    //메뉴 총 가격 계산하기
    function menuTotalPriceForBusket()public view returns(uint){
        uint totalPrice;
        uint menuLength = customers[msg.sender].busket.menuName.length;
        for (uint i = 0; i < menuLength; i++) {
            totalPrice += customers[msg.sender].busket.menuName[i].price*customers[msg.sender].busket.menuName[i].count;
        }
        return totalPrice;
    }

    //주문하기
    function ordering(uint _deliveryTip) public {
        //고객정보에 주문 추가
        Order memory newOrder = customers[msg.sender].goingOrder;
        newOrder.orderID=0;
        newOrder.customerAddr=msg.sender;
        newOrder.storeAddr=customers[msg.sender].busket.storeAddr;
        newOrder.customerAddress=customers[msg.sender].busket.customerAddress;
        newOrder.storeAddress=customers[msg.sender].busket.storeAddress;
        newOrder.menuName=customers[msg.sender].busket.menuName;
        newOrder.foodPrice=menuTotalPriceForBusket();
        newOrder.deliveryFee=0;
        newOrder.deliveryTip=_deliveryTip;
        newOrder.storeStatus=storeState.notyetChoice;
        newOrder.riderStatus=riderState.notSelected; 
        
        //가게(가게맵핑)에 주문 추가
        Order memory newOrder2 = stores_owner[customers[msg.sender].busket.storeAddr].orderList.push();
        newOrder2.orderID=0;
        newOrder2.customerAddr=msg.sender;
        newOrder2.storeAddr=customers[msg.sender].busket.storeAddr;
        newOrder2.customerAddress=customers[msg.sender].busket.customerAddress;
        newOrder2.storeAddress=customers[msg.sender].busket.storeAddress;
        newOrder2.menuName=customers[msg.sender].busket.menuName;
        newOrder2.foodPrice=menuTotalPriceForBusket();
        newOrder2.deliveryFee=0;
        newOrder2.deliveryTip=_deliveryTip;
        newOrder2.storeStatus=storeState.notyetChoice;
        newOrder2.riderStatus=riderState.notSelected;

        //배달 목록에 등록
        deliveryWaitingList.push(customers[msg.sender].goingOrder);
    }





/*여기서부터 재수정시작 => 주문수락,배달건 선택,요리완성 등에서 어떤 주문을 수락, 선택 ,완성
 하였는지 몰라서  주문건의 고유번호가 필요할 것 같음*/





    //가게의 주문 수락
    function storeAccept(uint _n) public {
        //고객의 order상태 변경
        customers[stores_owner[msg.sender].orderList[_n].customerAddr].goingOrder.storeStatus = storeState.accept;
        //가게(stores_owner)의 order상태 변경
        stores_owner[msg.sender].orderList[_n].storeStatus = storeState.accept; 
    }

    //가게의 주문 거절
    function storeDecline(uint _n) public {
        //고객의 order상태 변경
        customers[stores_owner[msg.sender].orderList[_n].customerAddr].goingOrder.storeStatus = storeState.decline;
        //가게(stores_owner)의 order상태 변경
        stores_owner[msg.sender].orderList[_n].storeStatus = storeState.decline;
    }

    //라이더의 배달건 선택
    function riderSelectOrder(uint _n)public{
        //주문건의 배달상태 '선택'
        deliveryWaitingList[_n].riderStatus=riderState.selected;
        //고객의 order상태 변경
        customers[stores_owner[msg.sender].orderList[_n].customerAddr].goingOrder.riderStatus = riderState.selected;
        //고객 주문에 rider등록
        customers[stores_owner[msg.sender].orderList[_n].customerAddr].goingOrder.riderAddr = msg.sender;
        //가게(stores_owner)의 order상태 변경
        stores_owner[msg.sender].orderList[_n].riderStatus = riderState.selected;
    }

    //주문건 조건이 맞을경우, 컨트랙트에 돈 지불
    function payment()public payable {
        //고객 주문건이 가게는수락, 라이더는 배달하기로 선택한 상태
        require(customers[msg.sender].goingOrder.storeStatus == storeState.accept &&
                customers[msg.sender].goingOrder.riderStatus == riderState.selected
        );
        //컨트랙트에 가격지불
        require(
            msg.value==customers[msg.sender].goingOrder.foodPrice+
            customers[msg.sender].goingOrder.deliveryFee+
            customers[msg.sender].goingOrder.deliveryTip
            );
        //가게(stores_owner)의 order상태 변경
        for(uint i=0;i<stores_owner[customers[msg.sender].goingOrder.storeAddr].orderList.length;i++){
            if(stores_owner[customers[msg.sender].goingOrder.storeAddr].orderList[i].customerAddr == msg.sender){
                stores_owner[customers[msg.sender].goingOrder.storeAddr].orderList[i].storeStatus = storeState.checkMoney;
            }
        }
        //배달조회목록주문건의 상태변경경
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].customerAddr == msg.sender && deliveryWaitingList[i].storeAddr ==customers[msg.sender].goingOrder.storeAddr){
                deliveryWaitingList[i].storeStatus = storeState.checkMoney;
            }
        }
        //고객의 order상태 변경
        customers[msg.sender].goingOrder.storeStatus = storeState.checkMoney;
    }

    function cookFinish(uint _n)public {
        //가게(stores_owner)의 order상태 변경
        stores_owner[msg.sender].orderList[_n].storeStatus = storeState.cookFinish;
        //고객의 order상태 변경
        customers[stores_owner[msg.sender].orderList[_n].customerAddr].goingOrder.storeStatus = storeState.cookFinish;
    }


    //라이더의 배달 선택
    function riderPickOrder(uint _n)public {
        //라이더의 배달목록에 추가가
        riders[msg.sender].orders.push(deliveryWaitingList[_n]);
        //배달 대기목록의 주문건 상태 수정
        deliveryWaitingList[_n].storeStatus=storeState.isPicked;
        deliveryWaitingList[_n].riderStatus=riderState.isPicked;
        //고객,가게의 주문건 상태 수정
        for(uint i=0;i<stores_owner[deliveryWaitingList[_n].storeAddr].orderList.length;i++){
            if(stores_owner[deliveryWaitingList[_n].storeAddr].orderList[i].customerAddr == deliveryWaitingList[_n].customerAddr){
               stores_owner[deliveryWaitingList[_n].storeAddr].orderList[i].storeStatus = storeState.isPicked;
                stores_owner[deliveryWaitingList[_n].storeAddr].orderList[i].riderStatus = riderState.isPicked;
                customers[deliveryWaitingList[_n].customerAddr].goingOrder.storeStatus = storeState.isPicked;
                customers[deliveryWaitingList[_n].customerAddr].goingOrder.riderStatus = riderState.isPicked;
            }
        }
    }
}
