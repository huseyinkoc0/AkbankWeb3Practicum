// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract CrowdFund {

    struct Campaign {
        address creator;  
        uint goal;       
        uint32 startAt;   
        uint32 endAt;    
        bool claimed;     
        uint pledged;    
    }

    
    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Refund(uint indexed id, address indexed caller, uint amount);
    event Cancel(uint id);
    event Claim(uint id);


    IERC20 public immutable token; 
    uint public count;  // count of campaigns
    mapping(uint => Campaign) public campaigns; // list of campaigns with indexes
    mapping(uint => mapping(address => uint)) public pledgedAmount; // list of pledged amounts

    
    constructor(address _token) {
        token = IERC20(_token);
    }

    
    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
       
        require(_startAt >= block.timestamp, "Start at < Now");
        require(_endAt >= _startAt, "End at < Start at");
        require(_endAt <= block.timestamp + 90 days, "End at > Max duration");

       
        count += 1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged : 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed : false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

 
    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        
        require(msg.sender == campaign.creator, "You're not a creator");
        require(block.timestamp < campaign.startAt, "Already started");
        delete campaigns[_id];
        emit Cancel(_id);
    }


    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "Not started");
        require(block.timestamp <= campaign.endAt, "Already ended");
        pledgedAmount[_id][msg.sender] += _amount;
        campaign.pledged += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "Already ended"); 
        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
        emit Unpledge(_id, msg.sender, _amount);
    }

  
    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
      
        require(msg.sender == campaign.creator, "You're not a creator");
      
        require(block.timestamp > campaign.endAt, "Not ended"); 
     
        require(campaign.pledged >= campaign.goal, "Pledged < Goal");
     
        require(!campaign.claimed, "Already claimed");

        campaign.claimed = true;
     
        token.transfer(msg.sender, campaign.pledged);
        
        emit Claim(_id);
    }

  
    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
      
        require(block.timestamp > campaign.endAt, "Not ended"); 
      
        require(campaign.pledged < campaign.goal, "Pledged >= Goal");

     
        uint balance = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, balance);
 
        emit Refund(_id, msg.sender, balance);
    }

}
