// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

contract LocalKorner {

  uint256 private pizzaPrice;
  address private owner;
  address private ultimateOwner; 
  bool isActivated;
  bool private pizzaPayed;


  struct Pizza{
    uint pizzaId;
    string pizzaName;     
  }
  
  struct Order{
    uint pizzaId;
    string pizzaName;
    uint pizzaAmount;    
  }

  //mapping(uint => string) idToPizza;         //connects id with pizzaname
  mapping(address => Order[]) myPizzaOrder;  //msg.sender to orders
  mapping(address => uint) orderAmount;      //counts the customers order amount
  mapping(address => bool) isRegistered;     //is address registered
  mapping(address => uint) customerId;       //gives an ID to a customer
  mapping(address => uint) orderCount;       //counts orders for free pizza 
  mapping(address => bool) isOwner;          //is msg.sender owner 
  //mapping(address => bool) accessApproved;   //owners approvals  
  //mapping(address => bool) canAccess;        //requests sender grant access

  event OrderSent(uint orderId, address customer, string message);
  event FreePizza(uint orderId, address customer, string message);
  event KornerOwnership(address owner, string message);
  event UltimateOwnership(address ultimateOwner, string message);

  address[] private owners;
  Pizza[] private pizzas;
  Order[] private orders;

  modifier onlyOwner {
      require(owner == msg.sender || isOwner[msg.sender], "not owner");
      _;
   }

  modifier dontUse {
    require(owners.length >= 2 && isActivated == false, "don't use");
    _;
  } 

  modifier ultimateActivated {
     if(isActivated == true){
       require(msg.sender == ultimateOwner,
        "only one owner");
        _;
     }else{
       _;
     }
   }

  modifier multiOwner {
    require(owners.length == 1 || msg.sender == ultimateOwner,"get access from owners");
      _;
    }

   modifier preventDoubleReg {
     require(!isRegistered[msg.sender], "registered");
     _;
   }

   modifier freePizza {
     _freePizza();
     _;
   }
 
    constructor() {


    owner = msg.sender;
    owners.push(msg.sender);
    
    emit KornerOwnership(owner, "welcome boss");
  }

  function setUltimateOwnership(address _ultimateOwner) external onlyOwner multiOwner dontUse {
      require(_ultimateOwner != address(0), "can't be zero address");
      ultimateOwner = _ultimateOwner;
      delete owners;
      owners.push(_ultimateOwner);
      isActivated = true;

      emit UltimateOwnership(ultimateOwner, "is now the owner"); 
    }

  function addOwnership(address _newOwner) external onlyOwner multiOwner ultimateActivated {
      require(_newOwner != address(0), "can't be zero address");
      owners.push(_newOwner);
      isOwner[_newOwner] = true;
    }

  function removeOwnership(address _oldOwner, uint _slotNumber) external onlyOwner multiOwner ultimateActivated{
      require(_oldOwner != address(0), "can't be zero address");
      owners[_slotNumber] = owners[owners.length - 1];
      owners.pop();
      isOwner[_oldOwner] = false;
     }

    function _setPrice(uint256 _pizzaPrice) external onlyOwner multiOwner ultimateActivated {       
      if(owners.length == 1 || msg.sender == ultimateOwner){     
        pizzaPrice = _pizzaPrice;
      }
      else {
        pizzaPrice = _pizzaPrice;
      }
    }

    function getPizzaPrice() external view returns(uint) {
      return pizzaPrice;
    }

    function setMyRegId() external preventDoubleReg {
      uint newId = block.timestamp + 2;
      customerId[msg.sender] = newId;
      isRegistered[msg.sender] = true;
      }

    function getMyRegId() external view returns(uint) {
      require(isRegistered[msg.sender], "register first");
      return customerId[msg.sender];
    }

    function createPizza(uint _pizzaId, string memory _pizzaName) external onlyOwner multiOwner ultimateActivated {
        pizzas.push(Pizza(_pizzaId, _pizzaName));
        //idToPizza[_pizzaId] = _pizzaName;
    }

    function deletePizza(uint whichSlotToDelete) external onlyOwner multiOwner ultimateActivated{
        pizzas[whichSlotToDelete] = pizzas[pizzas.length - 1];
        pizzas.pop();
    }

    function getPizzaTypes() external view returns(Pizza[] memory) {
        return pizzas;
         }
    
    function checkBonusStatus() external view returns(uint) {
        return orderCount[msg.sender];
    }

    function _orderSent() private {
        delete myPizzaOrder[msg.sender];
        orderAmount[msg.sender] = 0;
        orderCount[msg.sender] = 0;
    }

    function _freePizza() private {
        if (orderCount[msg.sender] == 5) {
        require(msg.value == 0, "don't pay");
        _orderSent();
        emit FreePizza(block.timestamp, msg.sender, "order sent");
     }
    }

    function createOrder(uint _pizzaId, string memory _pizzaName, uint _amount) external {
        require(isRegistered[msg.sender], "register first");
        //require(keccak256(abi.encode(_pizzaId)) == keccak256(abi.encode(pizzas)), "invalid order"); 
        require(_amount > 0, "no 0 amount");
        require(_amount <= 10, "order less than 10");

          myPizzaOrder[msg.sender].push(Order(_pizzaId, _pizzaName, _amount));
          orderAmount[msg.sender] += (_amount);
            
    }

    function checkMyOrder() external view returns(Order[] memory _myOrder,  uint _amountToPay) {
      require(orderAmount[msg.sender] > 0 , "order first");

        _myOrder = myPizzaOrder[msg.sender];
        _amountToPay = orderAmount[msg.sender] * pizzaPrice;
        
        return(_myOrder,  _amountToPay);
        }
    
    function deleteMyPizzaOrder() external {
      require(orderAmount[msg.sender] > 0 , "order first");        
        delete myPizzaOrder[msg.sender];
        orderAmount[msg.sender] = 0;
    }

    function payForPizza() external freePizza payable returns (bool pizzaIsPayed) {
      require(orderAmount[msg.sender] > 0, "no order yet");

      if (isActivated == false && (msg.sender == owner || isOwner[msg.sender])) {
        _orderSent();

        emit OrderSent(block.timestamp, msg.sender, "order sent");
        return !pizzaPayed;
      }
      else {
        require(msg.value == orderAmount[msg.sender] * pizzaPrice, "incorrect amount");
        delete myPizzaOrder[msg.sender];
        orderAmount[msg.sender] = 0;

        emit OrderSent(block.timestamp, msg.sender, "order sent");

        orderCount[msg.sender]++;
        return !pizzaPayed;
      }
    }
    
    function getContractBalance() external view onlyOwner multiOwner ultimateActivated returns (uint) {
        return address(this).balance;
    }
  
    function adminWithdraw() external onlyOwner multiOwner ultimateActivated returns (bool) {
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        return sent;
    }
 
    fallback() external payable {}
    receive() external payable {}
    }