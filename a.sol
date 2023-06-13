// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

contract first{

    // 매장 구조체
    struct Store {
        address storeWallet;
        string storeName;
        string storeAddress;
        mapping (string=>Menu) menus;
    }
    //메뉴 구조체 
    struct Menu {
        string foodName;
        uint foodPrice;
    }
    //가게이름 검색시 가게정보
    mapping(string=>Store) stores;


    //가게 생성 기능 
    function setStore(string memory _storeName, string memory _storeAddress) public {
        Store storage newStore = stores[_storeName];
        newStore.storeWallet = msg.sender;
        newStore.storeName = _storeName;
        newStore.storeAddress = _storeAddress;
    }

    //가게 메뉴 세팅기능
    function setStoreMenu(string memory _storeName,string memory _menuName,uint _price)public{
        stores[_storeName].menus[_menuName]=Menu(_menuName,_price);
    }

    

    //장바구니 구조체
    struct busket{
        address customerAddr;
        string  storeName;
        Menu[] menuName;
        uint deliveryPrice;
        uint tip;
        orderStatus status;
    }

    enum orderStatus{
        orderCancel,
        orderApproved,
        noSelected
    }

    //개인 장바구니 매핑
    mapping(address=>busket) buskets;
    
    //장바구니 만들기
    function createBusket()public view {
        
        busket memory newBusket = buskets[msg.sender];
        newBusket.customerAddr = msg.sender;
        newBusket.storeName = "";
        newBusket.deliveryPrice = 0;
        newBusket.tip = 0;
        newBusket.status = orderStatus.noSelected;
        newBusket.menuName = new Menu[](0);
        
        // buskets[msg.sender]=busket(msg.sender,"",new Menu[](0),0,0,orderStatus.noSelected);
    }

    //장바구니 담기기
    function setsBusket(string memory _storeName,string memory _menuName)public{
        buskets[msg.sender].menuName.push(stores[_storeName].menus[_menuName]);
    }

    //장바구니에 들어있는 모든 메뉴의 합
    function menuTotalPrice()public view returns(uint){
        uint totalPrice;
        uint menuLength = buskets[msg.sender].menuName.length;
        for (uint i = 0; i < menuLength; i++) {
        totalPrice += buskets[msg.sender].menuName[i].foodPrice;
        }
        // buskets[msg.sender].menuName=Menu[](buskets[msg.sender].menuName.length);
        // for(uint i=0;i<buskets[msg.sender].menuName.length;i++){
        //     totalPrice += buskets[msg.sender].menuName[i].foodPrice;
        // }
        return totalPrice;
    }

    mapping(address=>busket) orders;

    //장바구니 결제하기 버튼 눌렀을 때 실행, 주문건 생성성
    function customerPayToContract()public payable {
        require(msg.value==buskets[msg.sender].deliveryPrice+buskets[msg.sender].tip+menuTotalPrice());
        orders[msg.sender]=buskets[msg.sender];
    }

    //가게 주문 수락 시, 메뉴가격 컨트랙트=>가게, 취소 시 전액 돌려주기
    function storeOrderSelect()public {
        if(orders[msg.sender].status==orderStatus.orderCancel){
            payable (msg.sender).transfer((buskets[msg.sender].deliveryPrice+buskets[msg.sender].tip+menuTotalPrice())*1 ether);
        }else if(orders[msg.sender].status==orderStatus.orderApproved){
            payable (stores[orders[msg.sender].storeName].storeWallet).transfer(menuTotalPrice()*1 ether);
        }
    }
}