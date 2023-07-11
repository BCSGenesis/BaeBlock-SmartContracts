// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./riderNft.sol";
import "./storeNft.sol";


contract Payment is Ownable {
// HS-rider 가져오기-----------------------------------------------------------------
   
    delivery riderContract;
    store Store;

    constructor(address _riderContractAddr,address _storeContractAddr){
        riderContract= delivery(payable (_riderContractAddr));
        Store= store(payable (_storeContractAddr));
    }

    uint platformFee = 2;   //플랫폼 수수료
    event Result(string message);

// 변수선언 -----------------------------------------------------------------------
    
    //주문 번호
    uint public orderID;       
    
    //주문 구조체
    struct Order {
        address cWallet;    //고객 지갑
        address sWallet;    //가게 지갑
        address rWallet;    //라이더 지갑
        uint foodPrice;     //음식 가격
        uint deliveryFee;   //거리에 따라 지정되는 배달비 (고객 + 가게)
        uint deliveryTip;   //배달팁
        orderState status;  //주문 상태
    }

    //주문상태
    enum orderState{
        order,
        store_accept,
        store_decline,
        store_cookFinish,
        rider_accept,
        rider_inDelivery,
        rider_deliveryComplete,
        done
    }
    

    //주문번호로 주문 조회 (orderID=>Order)
    mapping(uint => Order) searchOrder; 

    //역할
    enum Role{
        store,
        rider
    }

    //회원 구조체
    struct Member {
        address Wallet;
        Role role;
    }

    //회원 목록
    mapping(address => Member) members;

// 정보등록 -----------------------------------------------------------------------

    //회원가입
    function Register(uint _role) public {
        if(_role==1){
            members[msg.sender]= Member(msg.sender, Role.store);
        }else if(_role==2){
            members[msg.sender]= Member(msg.sender, Role.rider);
        }
    }

    //확인
    function returnRegister()public view returns(address,Role){
        return(members[msg.sender].Wallet, members[msg.sender].role);
    }

// 결제 ------------------------------------------------------------------------------
    //고객이 주문하고 돈을 보냄
    function ordering(address _sWallet, uint _foodPrice, uint _deliveryFee, uint _deliveryTip) public payable {
        require(msg.value == (_foodPrice + _deliveryFee + _deliveryTip));           //잔고 확인
        require(members[_sWallet].role == Role.store);                              //사용가능한 가게인지 확인
        searchOrder[orderID] = Order(msg.sender, _sWallet, address(0) ,_foodPrice, _deliveryFee, _deliveryTip, orderState.order);
        orderID++;
    }
    
    function returnOrderID()public view returns(uint){
        return orderID-1;
    }

    //확인
    function returnOrder(uint _orderID)public view returns(Order memory){
        return searchOrder[_orderID];
    }

    //가게 : 주문 수락시 배달비 지불 / 거절시 지불 안됨
    function storeAccept_Decline(uint _orderID, bool _bool) public payable {
        require(msg.sender == searchOrder[_orderID].sWallet, "You can't access this order.");           //가게 주인확인
        require(searchOrder[_orderID].status == orderState.order, "This order is not available.");      //주문 상태 확인
        if(_bool==true){
            require(msg.value == (searchOrder[_orderID].deliveryFee), "You should pay DeliveryFee");  //배달비 확인
            searchOrder[_orderID].status = orderState.store_accept;                                      //주문 수락
        }else{
            searchOrder[_orderID].status = orderState.store_decline;                                     //주문거절
            uint refundPrice = searchOrder[_orderID].foodPrice + searchOrder[_orderID].deliveryFee + searchOrder[_orderID].deliveryTip;
            payable (searchOrder[_orderID].cWallet).transfer(refundPrice);                               //환불 
        }
    }

    


    //orderState ; 확인
    function returnOrderState(uint _orderID)public view returns(orderState){
        return searchOrder[_orderID].status;
    }

    //가게 음식조리완료
    function cookFinish(uint _orderID) public {
        require(msg.sender == searchOrder[_orderID].sWallet);                    //가게 주인확인
        require(searchOrder[_orderID].status == orderState.store_accept);
        searchOrder[_orderID].status = orderState.store_cookFinish;
    }


    
    
    function getRiderNftTime()public  view returns(uint){
        return riderContract.getRiderNftTime(msg.sender);
    }
    function getStoreNftTime()public  view returns(uint){
        return Store.getStoreNftTime(msg.sender);
    }
    //배달선택(setDelivery)이 안되면, nftMarket가서 burn버튼 클릭하고,nft구매버튼으로 민팅팅
    function burnRiderNft()public {       
            riderContract.burn(msg.sender,riderContract.getRiderTokenId(msg.sender));        
    }
    function burnStoreNft()public {       
            Store.storeBurn(msg.sender,Store.getStoreTokenId(msg.sender));        
    }

    //web3에서 HS-rider컨트랙트의 getRiderNftTime(address)-getBlockTimeStamp() 값을 usestate변수로 받아 남은 일수 표현
    function getBlockTimeStamp()public view returns(uint){
        return block.timestamp;
    }

    //배달원 지정
    function setDelivery(uint _orderID) public  {
        require(members[msg.sender].role == Role.rider);                         //배달기사 회원가입여부 확인
        //이 배달기사가 배달 권한 nft를 가졌는지
        require(riderContract.getRiderNftTime(msg.sender)>=block.timestamp,"You don't have deliveryNft or Nft is expired");
        require(searchOrder[_orderID].rWallet == address(0));                    //배달기사 지정 안된 상태인지 확인
        require(searchOrder[_orderID].status == orderState.store_cookFinish); //가게가 주문 받은 상태인지 확인 
        searchOrder[_orderID].rWallet = msg.sender;
        searchOrder[_orderID].status = orderState.rider_accept;
    }

    

    //배달권 민팅은 원본컨트랙트에서 실행해야하는듯..msg.value가 전달이 안됨..
    
    //배달시작
    function startDelivery(uint _orderID)public{
        require(searchOrder[_orderID].rWallet == msg.sender);
        require(searchOrder[_orderID].status == orderState.rider_accept);
        searchOrder[_orderID].status = orderState.rider_inDelivery;
    }

    //배달완료
    function doneDelivery(uint _orderID) public {
        require(searchOrder[_orderID].rWallet == msg.sender);
        require(searchOrder[_orderID].status == orderState.rider_inDelivery);    
        searchOrder[_orderID].status = orderState.rider_deliveryComplete;
    }

    
    //거래 완료 후, 가게와 배달원에게 돈 입금
    function orderComplete(uint _orderID, bool) public {
        
        // store Store = new store();                                            //Genesis.sol 파일 인스턴스화
        uint nftOwner = Store.getMappingAccount(searchOrder[_orderID].sWallet);                            //tokenId가 저장되는 매핑 함수               
        require(searchOrder[_orderID].cWallet == msg.sender); // 고객이 음식받음 버튼을 누르면 지급됨
        uint totalFee = (searchOrder[_orderID].deliveryFee *2) + searchOrder[_orderID].deliveryTip;
        // + 일정시간이 지나거나 owner가 눌러줘도 가능하도록
        payable(searchOrder[_orderID].rWallet).transfer(totalFee); 

        if(nftOwner > block.timestamp ) { 
            emit Result("You have an NFT. Platform fees are waived.");
            payable(searchOrder[_orderID].sWallet).transfer(searchOrder[_orderID].foodPrice); 
            searchOrder[_orderID].status = orderState.done;
        } else{ 
             emit Result("You don't have an NFT or your usage period has expired.  The platform fee is 2% of the foodprice.");
             uint FoodPrice = searchOrder[_orderID].foodPrice;
             payable(searchOrder[_orderID].sWallet).transfer((FoodPrice-(FoodPrice * platformFee) /100)); //수수료 부과
             searchOrder[_orderID].status = orderState.done;
        }
    }

    //컨트랙트 돈 인출 
    function withdraw(uint _money) public onlyOwner{
        uint possible = address(this).balance -0/*출금불가한 금액*/;
        require(possible >0);
        payable(msg.sender).transfer(_money);
    }


    // function returnNftTimeRider()public view returns(uint){
    //     return riderContract.getRiderNftTime(msg.sender);
    // }
    // function returnNftTokenRider()public view returns(uint){
    //     return riderContract.getRiderTokenId(msg.sender);
    // }
    // function returnNftTimeStore()public view returns(uint){
    //     return Store.getMappingAccount(msg.sender);
    // }
}
