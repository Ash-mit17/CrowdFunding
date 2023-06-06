// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CrowdFunding{

    mapping(address=>uint) public contributor; //contributor address => amount
    address public manager;
    uint public minContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContibutors;

    struct Request{        //request by a organization asking money
        string description;  //name of organization
        address payable recipient; //address of the organization owner
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    mapping(uint=>Request) public requests;

    uint public numRequest;

    constructor(uint _target,uint _deadline){
        target=_target;
        deadline=block.timestamp+_deadline;
        minContribution=100 wei;
        manager=msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp < deadline,"Deadline is crossed ");
        require(msg.value >= minContribution,"Minimum contribution is 100 wei ");
        if(contributor[msg.sender] == 0)
        {
            noOfContibutors++;
        }
        contributor[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline && raisedAmount<target,"Eligible for refund");
        require(contributor[msg.sender]>0,"You are not a contributor");
        address payable user=payable(msg.sender);
        user.transfer(contributor[msg.sender]);
        contributor[msg.sender]=0;
    }

    modifier onlyManager(){
        require(msg.sender == manager,"Only manager can call this function");
        _;
    }

    function createRequest(string memory _description,address payable _recipient,uint _value) public onlyManager{
        Request storage newRequest = requests[numRequest];
        numRequest++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.noOfVoters=0;
        newRequest.completed=false;
    }

    function requestsInfo(uint request_no) public view returns(string memory,uint){
        Request storage checkRequest = requests[request_no];
        return(checkRequest.description,checkRequest.value);
    }

    function voteRequest(uint request_no) public{
        require(contributor[msg.sender] > 0,"You must me a contributor");
        Request storage thisRequest = requests[request_no];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint request_no) public{
        require(raisedAmount >= target);
        Request storage thisRequest = requests[request_no];
        require(thisRequest.completed == false,"The request has already been made");
        require(thisRequest.noOfVoters > noOfContibutors/2,"No majority");
        thisRequest.recipient.transfer(thisRequest.value);//transfer the money to the recipient address
        thisRequest.completed = true;
    }
}