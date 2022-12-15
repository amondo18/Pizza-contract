// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

contract Ownership {

  address private owner;
  address private ultimateOwner;
  bool isActivated;

  event KornerOwnership(address owner, string message);
  event UltimateOwnership(address ultimateOwner, string message);
  event SubmitRequest(address indexed from, string indexed message, uint indexed _id);
  event Approved(address indexed owner);


  //is msg.sender owner
  mapping(address => bool) isOwner;
  //owners approvals
  mapping(address => bool) accessApproved;
  //request sender grant access
  mapping(address => bool) canAccess;

  struct OwnerAccessRequest{
    address from;
    string request;
    uint id;
    bool gotAccess;
  }

  address[] private owners;
  OwnerAccessRequest[] private requests;

  modifier onlyOwner {
      require(owner == msg.sender || isOwner[msg.sender], "You are NOT the owner!");
      _;
   }

  modifier dontUse {
    require(owners.length >= 2 && isActivated == false, "Don't need to use this, you're the only owner");
    _;
  } 

  modifier ultimateActivated {
     if(isActivated == true){
       require(msg.sender == ultimateOwner,
        "Ultimate ownership has been activated. You're not the owner any more.");
        _;
     }else{
       _;
     }
   }

  modifier multiOwner {
    require(owners.length == 1 || msg.sender == ultimateOwner,"Get access from owners.");
      _;
    }
  

  function setUltimateOwnership(address _ultimateOwner) external onlyOwner multiOwner dontUse {
      require(_ultimateOwner != address(0), "New owner can not be zero address!");
      ultimateOwner = _ultimateOwner;
      delete owners;
      owners.push(_ultimateOwner);
      isActivated = true;

      emit UltimateOwnership(ultimateOwner, "is now the ultimate and only owner!"); 
    }

  function addOwnership(address _newOwner) external onlyOwner multiOwner ultimateActivated {
      require(_newOwner != address(0), "New owner can not be zero address!");
      owners.push(_newOwner);
      isOwner[_newOwner] = true;
    }

  function removeOwnership(address _oldOwner, uint _slotNumber) external onlyOwner multiOwner ultimateActivated{
      require(_oldOwner != address(0), "New owner can not be zero address!");
      owners[_slotNumber] = owners[owners.length - 1];
      owners.pop();
      isOwner[_oldOwner] = false;
     }

  function getOwnerRequests() external view onlyOwner ultimateActivated dontUse returns(OwnerAccessRequest[] memory) {
      return requests;
    }

  function submitRequest(address _owner, string memory _message) external onlyOwner ultimateActivated dontUse {
      requests.push(OwnerAccessRequest({
        from: _owner,
        request: _message,
        id: block.timestamp,
        gotAccess: false
      }));
      emit SubmitRequest(msg.sender, _message, requests.length - 1);
    }

  function approveRequest() external onlyOwner ultimateActivated dontUse {
      require(requests.length > 0, "Request needed.");
      accessApproved[msg.sender] = true;
      emit Approved(msg.sender);
    }

  function _getApprovalCount() private view returns(uint count) {
      for(uint i; i < owners.length; i++) {
        if(accessApproved[owners[i]]) {
          count += 1;
      }
    }
  }

  function getAccess() external onlyOwner ultimateActivated dontUse {
      require(_getApprovalCount() > owners.length / 2, "Need more approvals.");
  }

  function getOwners() external view onlyOwner returns(address[] memory) {
      return owners;
    }

}

library Helper{
  
}

contract LocalKorner is Ownership {


  address private owner;
  address private ultimateOwner;
  uint256 private pizzaPrice;
  bool private pizzaPayed;
  //bool isActivated;


  struct Pizza{
      string pizzaName;
      uint pizzaId;
  }
  
  struct Order{
    string pizzaOrderName;
    uint pizzaAmount;    
  }

  //struct OwnerModifRequest{
    //string request;
    //bool approvedByMajority;
    //bool isUsed;
  //}

  //mapping (string => mapping(uint => bool)) isPizzaNameToId;
  //msg.sender to ordered pizzas;
  mapping(address => Order[]) myPizzaOrder;
  //counts the customers order amount
  mapping(address => uint) orderAmount;
  //is address registered
  mapping(address => bool) isRegistered;
  //gives an ID to a customer
  mapping(address => uint) customerId;
  //counts orders for free pizza
  mapping(address => uint) orderCount;
  //is msg.sender owner
  //mapping(address => bool) isOwner;
  //counts owners approvals
 // mapping(uint => mapping(address => bool)) approved;


  //event KornerOwnership(address owner, string message);
  //event UltimateOwnership(address ultimateOwner, string message);
  //event SubmitRequest(address indexed from, string indexed message, uint indexed slot);
  //event Approved(address indexed owner, uint indexed _requestId);
  //event AgreedToChange(uint indexed _requestId);
  //event RevokeApproval(address indexed owner, uint indexed _requestId);
  event OrderSent(uint orderId, address customer, string message);
  event FreePizza(uint orderId, address customer, string message);

  address[] private owners;
  OwnerAccessRequest[] private requests;
  Pizza[] private pizzas;
  Order[] private orders;

 
//   modifier onlyOwner {
//      require(owner == msg.sender || isOwner[msg.sender], "You are NOT the owner!");
//      _;
//   }

   modifier preventDoubleReg {
     require(!isRegistered[msg.sender], "You have already registered!");
     _;
   }

   modifier freePizza {
     _freePizza();
     _;
   }
 
  constructor() {

    owner = msg.sender;
    owners.push(msg.sender);
    
    emit KornerOwnership(owner, "Welcome boss.");
  }

    function _setPrice(uint256 _pizzaPrice) external onlyOwner multiOwner ultimateActivated {       
      if(owners.length == 1 || msg.sender == ultimateOwner){     
        pizzaPrice = _pizzaPrice;
      }
      else {
        //require(OwnerAccessRequest.gotAccess == true, "No access granted.");
        pizzaPrice = _pizzaPrice;
      }
    }

    function getPizzaPrice() external view returns(uint _pizzaPrice) {
    }

    function setMyRegId() external preventDoubleReg {
      uint newId = block.timestamp + 2;
      customerId[msg.sender] = newId;
      isRegistered[msg.sender] = true;
      }

    function getMyRegId() external view returns(uint) {
      require(isRegistered[msg.sender], "Please make registration first.");
      return customerId[msg.sender];
    }

    function createPizza(string memory _pizzaName, uint _pizzaId) external onlyOwner multiOwner ultimateActivated {
        pizzas.push(Pizza(_pizzaName, _pizzaId));
    }

    function deletePizza(uint whichSlotToDelete) external onlyOwner multiOwner ultimateActivated{
        pizzas[whichSlotToDelete] = pizzas[pizzas.length - 1];
        pizzas.pop();
    }

    function _freePizza() internal {
           if (orderCount[msg.sender] == 5) {
       require(msg.value == 0, "SURPRISE! You don't have to pay for this order :)");
       delete myPizzaOrder[msg.sender];
        orderAmount[msg.sender] = 0;
        orderCount[msg.sender] = 0;
        emit FreePizza(block.timestamp, msg.sender, "Order sent! This one is on the house :)");
     }
    }


    function createOrder(string memory _pizzaName, uint _amount) external {
        require(isRegistered[msg.sender], "Please make registration first.");
        //require(pizzaNameHasId, "Please select an existing pizzaname."); 
        require(_amount > 0, "You can't order 0 amount.");
        require(_amount <= 10, "Don't be that hungry,please order less than 10 pizzas.");

        //if anyone knows the solution pls DM me  
        //require(keccak256(abi.encode(_pizzaName)) == keccak256(abi.encode(pizzas)), "Please write a valid pizzaname.");

          myPizzaOrder[msg.sender].push(Order(_pizzaName, _amount));
          orderAmount[msg.sender] += (_amount);
            
    }

    
    function deleteMyPizzaOrder() external {
      require(orderAmount[msg.sender] > 0 , "Please make an order first.");        
        delete myPizzaOrder[msg.sender];
        orderAmount[msg.sender] = 0;
    }

    function payForPizza() external freePizza payable returns (bool pizzaIsPayed) {
      require(orderAmount[msg.sender] > 0, "No pizza has been ordered yet!");

      if (isActivated == false && (msg.sender == owner || isOwner[msg.sender])) {
        delete myPizzaOrder[msg.sender];
        orderAmount[msg.sender] = 0;

        emit OrderSent(block.timestamp, msg.sender, "Order sent! Thank you boss :)");
        return !pizzaPayed;
      }
      else {
        require(msg.value == orderAmount[msg.sender] * pizzaPrice, "Not enough ether payed!");
        delete myPizzaOrder[msg.sender];
        orderAmount[msg.sender] = 0;

        emit OrderSent(block.timestamp, msg.sender, "Order sent! Thank you :)");

        orderCount[msg.sender]++;
        return !pizzaPayed;
      }
 
    }
    

    function adminWithdraw() external onlyOwner multiOwner ultimateActivated returns (bool) {
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        return sent;
    }
 
    fallback() external payable {}
    receive() external payable {}
    }