//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OF {

    struct Plan {
        address merchant;
        address token;
        uint amount;
        uint frequency;
    }
    struct Subscription {
        address subscriber;
        uint start;
        uint nextPayment;
    }

    address owner;
    mapping(address => mapping(address => bool)) public isFan;
    mapping(address => bool) public isCreator;
    mapping(address => uint) public addressToPostId;

    //address to post id to their posts
    mapping(address => mapping(uint => string)) public addressToPosts;
    mapping(address => Plan) public plans;
    mapping(address => mapping(address => Subscription)) public subscriptions;
    
    event PostCreated(
        address creator,
        string imgHash
    );

    event PaymentSent(
        address from,
        address to,
        uint amount,
        uint date
    );

    event PlanCreated(
        address merchant,
        uint date
    );

    event SubscriptionCreated(
        address subscriber,
        uint date
    );

    event SubscriptionCancelled(
        address subscriber,
        address creator,
        uint date
    );

    function createPlan(address token, uint amount, uint frequency) external { //token:0x01BE23585060835E02B77ef475b0Cc51aA1e0709
        require(token != address(0), "address cannot be null address");
        require(amount > 0, "amount needs to be > 0");
        require(frequency > 0, "frequency needs to be > 0");
    
        plans[msg.sender] = Plan(
        msg.sender, 
        token,
        amount, 
        frequency
        );
        isCreator[msg.sender] = true;
    }

    function subscribe(address creator) external {
        
        IERC20 token = IERC20(plans[creator].token);
        Plan storage plan = plans[creator];
        require(plan.merchant != address(0), "this plan does not exist");
        
        token.transferFrom(msg.sender, plan.merchant, plan.amount);  
        emit PaymentSent(
            msg.sender, 
            plan.merchant, 
            plan.amount, 
            block.timestamp
        );

        subscriptions[msg.sender][creator] = Subscription(
            msg.sender, 
            block.timestamp, 
            block.timestamp + plan.frequency
        );
        isFan[creator][msg.sender] = true;
        emit SubscriptionCreated(msg.sender, block.timestamp);

    }


    function cancel(address creator) external {
        Subscription storage subscription = subscriptions[msg.sender][creator];
        require(
        subscription.subscriber != address(0), 
        "this subscription does not exist"
        );
        delete subscriptions[msg.sender][creator]; 
        isFan[creator][msg.sender] = false;
        emit SubscriptionCancelled(msg.sender, creator, block.timestamp);
    }

    function pay(address subscriber, address creator) external {

        Subscription storage subscription = subscriptions[subscriber][creator];
        Plan storage plan = plans[creator];
        IERC20 token = IERC20(plan.token);
        require(
        subscription.subscriber != address(0), 
        "this subscription does not exist"
        );
        require(
        block.timestamp > subscription.nextPayment,
        "not due yet"
        );

        token.transferFrom(subscriber, plan.merchant, plan.amount);  
        emit PaymentSent(
        subscriber,
        plan.merchant, 
        plan.amount, 
        block.timestamp
        );
        subscription.nextPayment = subscription.nextPayment + plan.frequency;
    }

    //input the encrypted version of the link (https://ipfs.infura.io/ipfs/QmS7V7vCLvPQrkijugcL3U5gXe4W2hU5tN5ovmVbBeFLPQ)
    function post(string memory imgHash) public { 
        isCreator[msg.sender] = true;
        addressToPostId[msg.sender] += 1;
        addressToPosts[msg.sender][addressToPostId[msg.sender]] = imgHash;
        emit PostCreated(msg.sender, imgHash);
    }

    function getPost(address creator) public returns (string[] memory) {
        require(isFan[creator][msg.sender] == true, "you are not a fan");
        for (uint i = 0; i < addressToPostId[msg.sender]; i++){
            return addressToPosts[creator][i]; // decrypt in the frontend 
        } 
    }
}
