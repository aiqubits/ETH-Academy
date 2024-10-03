// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// @title Ballot
contract Ballot {
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint vote; // index of the voted proposal
    }

    /// 提案类型
    struct Proposal {
        bytes32 name; // 简称，最长24字节
        uint voteCount; // 得票数
    }

    address public chairperson;
    uint public startTime; // 投票开始时间
    uint public endTime;   // 投票结束时间

    // 声明状态变量，为每个可能的地址存储一个Voter结构
    mapping(address => Voter) public voters;

    // 所有提案
    Proposal[] public proposals;
    
    /// 为`proposalNames` 中的每个提案创建一个Proposal结构，并将其添加到`proposals`数组中
    constructor(bytes32[] memory proposalNames, uint _startTime, uint _endTime) {
        require(_startTime < _endTime, "Start time must be before end time");

        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        startTime = _startTime;
        endTime = _endTime;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    // 给`voter`增加权重，表示有被投票的权力
    function giveRightToVote(address voter) external {
        require(
            msg.sender == chairperson,
            "only chairperson can give right to vote"
        );
        require(!voters[voter].voted, "voter already voted");
        require(voters[voter].weight == 0, "voter already has weight");
        voters[voter].weight = 1;
    }

    // 设置选民的投票权重
    function setVoterWeight(address voter, uint weight) external {
        require(msg.sender == chairperson, "Only chairperson can set voter weight");
        require(block.timestamp < startTime, "Cannot set weight after voting has started");
        require(weight > 0, "Weight must be greater than zero");

        voters[voter].weight = weight;
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no rtght to vote");
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation isdisallowed.");
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }
        Voter storage delegate_ = voters[to];
        require(delegate_.weight >= 1);
        sender.voted = true;
        sender.delegate = to;
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposal) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Voting is not within the allowed time frame");

        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no rtght to vote");    
        require(!sender.voted, "You already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    function winnerName() public view returns (bytes32 winnerName_) {
        uint winningProposal_ = winningProposal();
        winnerName_ = proposals[winningProposal_].name;
    }
}
