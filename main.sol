// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract Payment {
    struct Store {
        address payable storeWallet;
        string storeName;
        string storeAddress;
        mapping (string=>Menu[]) menuList;
        mapping(address=>Order) orderList;
    }


    mapping(address => Store) stores;


    struct Customer {
        address payable customerWallet;
        string customerAddress;
        //string id;
        //string password;
        //uint orderID;
        Order busket;
        mapping(address=>Order) orderList;
    }

    mapping(address => Customer) customers;

    struct Rider {
        address payable riderWallet;
        Order[] orders;
    }

    mapping(address => Rider) riders;

    struct Menu {
        string name;
        uint price;
        uint count;
    }


    struct Order {
        // 주문 번호 (고객 지갑으로 해도 될지?? 근데 고객 지갑으로 하면 주문 번호가 겹치는데 그래도 되는지..?)
        uint orderID;
        address customerAddr;
        address storeAddr;
        // 고객 주소 (라이더가 조회)
        string customerAddress;
        // 주문한 음식과 개수를 매칭해야 함.
        Menu[] menuName;
        // 음식 가격 (매장이 조회)
        uint foodPrice;
        // 기본 배달료 (라이더가 조회)
        uint deliveryFee;
        // 추가 배달팁 (라이더가 조회)
        uint deliveryTip;
        // 픽업 완료

        storeState storeStatus;
        riderState riderStatus;
    }
    enum storeState {decline, accept,cookFinish, isPicked,notyetChoice,checkMoney}
    enum riderState {selected,notSelected, inDelivery, isPicked, deliveryComplete}

    mapping(address => Order) busketList;
    


    function storeRegist(string memory _storeName,string memory _storeAddress) public {
        Store storage newStore=stores[msg.sender];
        newStore.storeWallet = payable(msg.sender);
        newStore.storeName = _storeName;
        newStore.storeAddress = _storeAddress;
    }

    function storeMenuRegist(address  _address,string memory _menuName,uint _price)public{
        stores[_address].menuList[_menuName].push(Menu(_menuName,_price,0));
    }


    function customerRegist() public {
        customers[msg.sender].customerWallet = payable(msg.sender);
    }


    function riderRegist() public {
        riders[msg.sender].riderWallet = payable(msg.sender);
    }

    function ordering() public view{
        //고객정보에 주문 추가가
        Order memory newOrder = customers[msg.sender].orderList[customers[msg.sender].busket.storeAddr];
        newOrder.orderID=0;
        newOrder.customerAddr=msg.sender;
        newOrder.storeAddr=customers[msg.sender].busket.storeAddr;
        newOrder.customerAddress=customers[msg.sender].busket.customerAddress;
        newOrder.menuName=customers[msg.sender].busket.menuName;
        newOrder.foodPrice=menuTotalPrice();
        newOrder.deliveryFee=0;
        newOrder.deliveryTip=0;
        newOrder.storeStatus=storeState.notyetChoice;
        newOrder.riderStatus=riderState.notSelected; 
        //가게에 주문 추가
        Order memory newStoreOrder= stores[customers[msg.sender].busket.storeAddr].orderList[msg.sender];
        newStoreOrder.orderID=0;
        newStoreOrder.customerAddr=msg.sender;
        newStoreOrder.storeAddr=customers[msg.sender].busket.storeAddr;
        newStoreOrder.customerAddress=customers[msg.sender].busket.customerAddress;
        newStoreOrder.menuName=customers[msg.sender].busket.menuName;
        newStoreOrder.foodPrice=menuTotalPrice();
        newStoreOrder.deliveryFee=0;
        newStoreOrder.deliveryTip=0;
        newStoreOrder.storeStatus=storeState.notyetChoice;
        newStoreOrder.riderStatus=riderState.notSelected; 
    }

    function menuTotalPrice()public view returns(uint){
        uint totalPrice;
        uint menuLength = busketList[msg.sender].menuName.length;
        for (uint i = 0; i < menuLength; i++) {
            totalPrice += busketList[msg.sender].menuName[i].price*busketList[msg.sender].menuName[i].count;
        }
        return totalPrice;
    }

    function storeAccept(address _customerAddr) public {
        //가게만실행가능능
        stores[msg.sender].orderList[_customerAddr].storeStatus = storeState.accept;
        customers[_customerAddr].orderList[msg.sender].storeStatus = storeState.accept;
    }
    

    function storeDecline(address _customerAddr) public {
        //가게만실행가능능
        stores[msg.sender].orderList[_customerAddr].storeStatus = storeState.decline;
        customers[_customerAddr].orderList[msg.sender].storeStatus = storeState.decline;
    }

    function payment()public payable {
        require(customers[msg.sender].orderList[customers[msg.sender].busket.storeAddr].storeStatus == storeState.accept);
        require(
            msg.value==customers[msg.sender].orderList[customers[msg.sender].busket.storeAddr].foodPrice+
            customers[msg.sender].orderList[customers[msg.sender].busket.storeAddr].deliveryFee+
            customers[msg.sender].orderList[customers[msg.sender].busket.storeAddr].deliveryTip
            );
        stores[customers[msg.sender].busket.storeAddr].orderList[msg.sender].storeStatus = storeState.checkMoney;
        customers[msg.sender].orderList[customers[msg.sender].busket.storeAddr].storeStatus = storeState.checkMoney;
    }

    Order[] deliveryWaitingList;

    function cookFinish(address _customerAddr)public {
        stores[msg.sender].orderList[_customerAddr].storeStatus = storeState.cookFinish;
        customers[_customerAddr].orderList[msg.sender].storeStatus = storeState.cookFinish;
        deliveryWaitingList.push(stores[customers[msg.sender].busket.storeAddr].orderList[msg.sender]);
    }

    function riderPickOrder(uint _n)public {
        riders[msg.sender].orders.push(stores[deliveryWaitingList[_n].storeAddr].orderList[deliveryWaitingList[_n].customerAddr]);
        deliveryWaitingList[_n].storeStatus=storeState.isPicked;
        deliveryWaitingList[_n].riderStatus=riderState.isPicked;
        stores[deliveryWaitingList[_n].storeAddr].orderList[deliveryWaitingList[_n].customerAddr].storeStatus = storeState.isPicked;
        stores[deliveryWaitingList[_n].storeAddr].orderList[deliveryWaitingList[_n].customerAddr].riderStatus = riderState.isPicked;
        customers[deliveryWaitingList[_n].customerAddr].orderList[deliveryWaitingList[_n].storeAddr].storeStatus = storeState.isPicked;
        customers[deliveryWaitingList[_n].customerAddr].orderList[deliveryWaitingList[_n].storeAddr].riderStatus = riderState.isPicked;
    }

}/*




    // createOrder에서는 가스비가 발생하지 않고, payment 함수에서만 가스비가 발생하게 할 수는 없을까?
    // order 함수에서 고객이 직접 입력하는 정보는 배달팁
    // 나머지는 리스트에서 선택하면 되는데 그 부분도 input으로 넣어야 하는지??
    function createOrder(uint _deliveryTip) public payable {
        // 고객이 매장의 메뉴를 선택하고 주문을 넣는다.
        

        ////////////////// 맵핑 방식 /////////////////////

        // 석훈님이 작성한 장바구니 코드 입니당.
        // 맵핑으로 관리하면 석훈님 쪽으로 짜면 될 것 같구요! 
        // 리스트로 관리하면 아래에 있는 방식으로 짜보면 될 것 같아요..!
        Order memory newOrder = bucketList[msg.sender];
        
        newOrder.customerAddress = msg.sender;
        newOrder.storeName = "";
        newOrder.deliveryFee = 0;
        newOrder.deliveryTip = _deliveryTip;
        newOrder.menuName = new Menu[](0);

        /////////////////////////////////////////////////



        //////////////////// 리스트 방식 //////////////////////

        // 가게 선택 하면 가게의 메뉴가 뜨고 그 메뉴를 누르면 가격이 반영
        // 이중맵핑을 사용 ??????
        // mapping(string => (string => uint)) menuPrice;

        uint foodPrice = menues[가게].[가격];
        // 거리별 기본 요금
        // 거리별 가격을 구하는 함수를 따로 만들어야 할지.. ㄱ-
        uint deliveryFee = distanceFee();
        // 전체 가격
        uint totalAmount = foodPrice + deliveryFee + deliveryTip;

        // orderID는 고객의 wallet 데이터와 order 숫자를 keccak으로 해서 저장? -> 겹치면 안되니까..

        // 주문 리스트에 해당 주문을 넣음.
        orderList.push();

        ///////////////////////////////////////////////////////
    }



    function storeAccept() public {
        // accept으로 바꿈
        주문[주문id].storeState = storeStatus.accept;
    }

    function riderChoice() public {
        // 라이더가 주문을 선택

    }

    // 주문의 라이더 배송 상태가 변경됨.
    function setRiderState() public {
        if(라이더state == deliveryFinished) {
            payment();
        }
    }

    // 뭔가 가게랑 라이더가 수락을 할 때 고객에게 이 함수가 자동으로 실행되면 좋을 것 같음.
    function payment() public payable {
        // 가게와 라이더가 수락을 해야.
        require(storeAccept());
        
        // 고객의 돈이 먼저 컨트랙트에 송금됌
        payable(address(this)).transfer(totalAmount);

        // 라이더 수익
        uint riderFee = orderList[orderID].deliveryFee + orderList[orderID].deliveryTip;

        // 가게 수익
        uint storeFee = orderList[orderID].foodPrice - orderList[orderID].deliveryFee;

        if (riderState == deliveryComplete) {
            (riders[라이더address].riderWallet).transfer(riderFee);
            (stores[가게address].storeWallet).transfer(storeFee);
        }
    }
}
*/