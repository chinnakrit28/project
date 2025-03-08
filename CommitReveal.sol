// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CommitReveal {

  uint8 public max = 100;

  // เพิ่ม address ที่อนุญาตให้เล่น
  address[4] public allowedPlayers = [
    0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
    0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
    0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
    0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
  ];

  // ฟังก์ชันตรวจสอบว่า address ที่เรียกใช้เป็น address ที่อนุญาตหรือไม่
  modifier onlyAllowedPlayers() {
    bool isAllowed = false;
    for (uint i = 0; i < allowedPlayers.length; i++) {
      if (msg.sender == allowedPlayers[i]) {
        isAllowed = true;
        break;
      }
    }
    require(isAllowed, "CommitReveal: You are not allowed to play.");
    _;
  }

  // การเลือกที่สามารถเลือกได้ในเกม RPSLS
  enum Choice { Rock, Paper, Scissors, Lizard, Spock }
  
  struct Commit {
    bytes32 commit;
    uint64 block;
    bool revealed;
    Choice choice; // การเลือกของผู้เล่น
  }

  mapping (address => Commit) public commits;

  event CommitHash(address sender, bytes32 dataHash, uint64 block);
  event RevealHash(address sender, bytes32 revealHash, uint random);

  // commit ข้อมูล
  function commit(bytes32 dataHash) public onlyAllowedPlayers {
    commits[msg.sender].commit = dataHash;
    commits[msg.sender].block = uint64(block.number);
    commits[msg.sender].revealed = false;
    emit CommitHash(msg.sender, commits[msg.sender].commit, commits[msg.sender].block);
  }

  // ฟังก์ชัน reveal ข้อมูล
  function reveal(bytes32 revealHash) public onlyAllowedPlayers {
    require(commits[msg.sender].revealed == false, "CommitReveal::reveal: Already revealed");
    commits[msg.sender].revealed = true;

    // ตรวจสอบว่าแฮชที่เปิดเผยตรงกับแฮชที่ commit
    require(getHash(revealHash) == commits[msg.sender].commit, "CommitReveal::reveal: Revealed hash does not match commit");

    // ตรวจสอบว่าเปิดเผยข้อมูลหลังจากบล็อกที่ commit
    require(uint64(block.number) > commits[msg.sender].block, "CommitReveal::reveal: Reveal and commit happened on the same block");
    require(uint64(block.number) <= commits[msg.sender].block + 250, "CommitReveal::reveal: Revealed too late");

    // คำนวณค่าที่สุ่มโดยใช้ block hash
    bytes32 blockHash = blockhash(commits[msg.sender].block);
    uint random = uint(keccak256(abi.encodePacked(blockHash, revealHash))) % max;

    // บันทึกการเลือกของผู้เล่น
    commits[msg.sender].choice = Choice(random % 5);  // 5 ตัวเลือก Rock, Paper, Scissors, Lizard, Spock

    emit RevealHash(msg.sender, revealHash, random);
  }

  // ฟังก์ชันคำนวณผู้ชนะ
  function checkWinner() public view returns (address winner) {
    require(commits[allowedPlayers[0]].revealed, "CommitReveal::checkWinner: Player 1 has not revealed.");
    require(commits[allowedPlayers[1]].revealed, "CommitReveal::checkWinner: Player 2 has not revealed.");

    Choice player1Choice = commits[allowedPlayers[0]].choice;
    Choice player2Choice = commits[allowedPlayers[1]].choice;

    if (player1Choice == player2Choice) {
      return address(0); // เสมอ
    }

    // คำนวณผลชนะ
    if ((player1Choice == Choice.Rock && (player2Choice == Choice.Scissors || player2Choice == Choice.Lizard)) ||
        (player1Choice == Choice.Paper && (player2Choice == Choice.Rock || player2Choice == Choice.Spock)) ||
        (player1Choice == Choice.Scissors && (player2Choice == Choice.Paper || player2Choice == Choice.Lizard)) ||
        (player1Choice == Choice.Lizard && (player2Choice == Choice.Spock || player2Choice == Choice.Paper)) ||
        (player1Choice == Choice.Spock && (player2Choice == Choice.Scissors || player2Choice == Choice.Rock))) {
      return allowedPlayers[0]; // ผู้เล่น 1 ชนะ
    } else {
      return allowedPlayers[1]; // ผู้เล่น 2 ชนะ
    }
  }

  // ฟังก์ชันคำนวณแฮชจากข้อมูล
  function getHash(bytes32 data) public pure returns(bytes32) {
    return keccak256(abi.encodePacked(data));
  }
}