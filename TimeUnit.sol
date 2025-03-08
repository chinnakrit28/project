// SPDX-License-Identifier: GPL-3.0 
pragma solidity >= 0.5.0 < 0.9.0; 

contract RPSLSGame {

    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => uint) public player_choice; // 0 - Rock, 1 - Paper, 2 - Scissors, 3 - Lizard, 4 - Spock
    mapping(address => bool) public player_not_played;
    address[] public players;
    uint public numInput = 0;
    uint public startTime; // เวลาเริ่มต้นเกม

    // 4 address ที่ได้รับอนุญาตให้เล่น
    address[4] public allowedPlayers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    modifier onlyAllowedPlayers() {
        bool isAllowed = false;
        for (uint i = 0; i < allowedPlayers.length; i++) {
            if (msg.sender == allowedPlayers[i]) {
                isAllowed = true;
                break;
            }
        }
        require(isAllowed, "RPSLS: You are not allowed to play.");
        _;
    }

    // ตัวเลือกของเกม: Rock, Paper, Scissors, Lizard, Spock
    enum Choice { Rock, Paper, Scissors, Lizard, Spock }

    // ฟังก์ชันเพิ่มผู้เล่น
    function addPlayer() public payable onlyAllowedPlayers {
        require(numPlayer < 2, "RPSLS: Only 2 players allowed.");
        if (numPlayer > 0) {
            require(msg.sender != players[0], "RPSLS: Player already joined.");
        }
        require(msg.value == 1 ether, "RPSLS: Must send 1 ether to play.");
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;

        if (numPlayer == 1) {
            startTime = block.timestamp; // ตั้งเวลาเริ่มต้นเมื่อผู้เล่นแรกเข้าร่วม
        }
    }

    // ฟังก์ชันให้ผู้เล่นเลือกตัวเลือก
    function input(uint choice) public {
        require(numPlayer == 2, "RPSLS: Both players must join.");
        require(player_not_played[msg.sender], "RPSLS: You have already made your choice.");
        require(choice >= 0 && choice <= 4, "RPSLS: Invalid choice. Choose a valid option.");

        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;

        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    // ฟังก์ชันคำนวณผู้ชนะและจ่ายรางวัล
    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        // คำนวณผู้ชนะตามกฎของ RPSLS
        if ((p0Choice == uint(Choice.Rock) && (p1Choice == uint(Choice.Scissors) || p1Choice == uint(Choice.Lizard))) ||
            (p0Choice == uint(Choice.Paper) && (p1Choice == uint(Choice.Rock) || p1Choice == uint(Choice.Spock))) ||
            (p0Choice == uint(Choice.Scissors) && (p1Choice == uint(Choice.Paper) || p1Choice == uint(Choice.Lizard))) ||
            (p0Choice == uint(Choice.Lizard) && (p1Choice == uint(Choice.Spock) || p1Choice == uint(Choice.Paper))) ||
            (p0Choice == uint(Choice.Spock) && (p1Choice == uint(Choice.Scissors) || p1Choice == uint(Choice.Rock)))) {
            // ผู้เล่น 0 ชนะ
            account0.transfer(reward);
        }
        else if ((p1Choice == uint(Choice.Rock) && (p0Choice == uint(Choice.Scissors) || p0Choice == uint(Choice.Lizard))) ||
                 (p1Choice == uint(Choice.Paper) && (p0Choice == uint(Choice.Rock) || p0Choice == uint(Choice.Spock))) ||
                 (p1Choice == uint(Choice.Scissors) && (p0Choice == uint(Choice.Paper) || p0Choice == uint(Choice.Lizard))) ||
                 (p1Choice == uint(Choice.Lizard) && (p0Choice == uint(Choice.Spock) || p0Choice == uint(Choice.Paper))) ||
                 (p1Choice == uint(Choice.Spock) && (p0Choice == uint(Choice.Scissors) || p0Choice == uint(Choice.Rock)))) {
            // ผู้เล่น 1 ชนะ
            account1.transfer(reward);
        }
        else {
            // เสมอ
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }

        // รีเซ็ตข้อมูลสำหรับรอบถัดไป
        numPlayer = 0;
        reward = 0;
        delete players;
    }

    // ฟังก์ชันตรวจสอบเวลาที่ผ่านไป
    function elapsedSeconds() public view returns (uint256) {
        return (block.timestamp - startTime);
    }

    function elapsedMinutes() public view returns (uint256) {
        return (block.timestamp - startTime) / 1 minutes;
    }
}
