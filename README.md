### การอธิบายโค้ด

### 1. **Contract: RPS (Rock, Paper, Scissors, Lizard, Spock)**

โค้ดนี้เป็นการสร้างเกม **Rock, Paper, Scissors** แต่ดัดแปลงเป็น **Rock, Paper, Scissors, Lizard, Spock** ซึ่งทำงานบนเครือข่าย **Ethereum** โดยใช้ **Solidity** เป็นภาษาการพัฒนา Smart Contract และมีฟังก์ชันการเล่นระหว่างผู้เล่น 2 คนที่สามารถเลือกตัวเลือกต่าง ๆ แล้วคำนวณผลจากตัวเลือกที่เลือก

### 2. **ตัวแปรหลัก (State Variables)**

```solidity
uint public numPlayer = 0;
uint public reward = 0;
mapping (address => uint) public player_choice; // 0 - Rock, 1 - Paper, 2 - Scissors
mapping(address => bool) public player_not_played;
address[] public players;
uint public numInput = 0;
```

- **numPlayer**: ตัวแปรนี้เก็บจำนวนผู้เล่นที่เข้าร่วมเกม (สูงสุด 2 คน)
- **reward**: ตัวแปรนี้เก็บจำนวน Ether ที่ใช้เป็นรางวัลในเกม
- **player_choice**: ตัวแปร mapping สำหรับเก็บตัวเลือกของผู้เล่น โดยใช้หมายเลขเพื่อแทนตัวเลือก (0 = Rock, 1 = Paper, 2 = Scissors, 3 = Lizard, 4 = Spock)
- **player_not_played**: ตัวแปร mapping ที่เช็คว่าผู้เล่นยังไม่ได้เลือกตัวเลือกในเกม
- **players**: รายการของผู้เล่นที่เข้าร่วมเกม (สูงสุด 2 คน)
- **numInput**: ตัวแปรที่เก็บจำนวนผู้เล่นที่ได้เลือกตัวเลือกแล้ว

### 3. **ฟังก์ชัน `addPlayer`**

```solidity
function addPlayer() public payable {
    require(numPlayer < 2, "Already two players in the game");
    require(msg.value == 1 ether, "Entry fee is 1 ether");

    // เช็คว่าผู้เล่นเป็นหนึ่งใน 4 address ที่ได้รับอนุญาต
    address[] memory allowedAddresses = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    bool isAllowed = false;
    for (uint i = 0; i < allowedAddresses.length; i++) {
        if (msg.sender == allowedAddresses[i]) {
            isAllowed = true;
            break;
        }
    }
    require(isAllowed, "You are not allowed to play");

    reward += msg.value;  // เพิ่มรางวัลจากการเข้าร่วมเกม
    players.push(msg.sender);  // เพิ่มผู้เล่นในรายการ
    numPlayer++;  // เพิ่มจำนวนผู้เล่น

    player_not_played[msg.sender] = true; // กำหนดว่าในตอนแรกผู้เล่นยังไม่ได้เลือก
}
```

- ฟังก์ชันนี้ใช้สำหรับเพิ่มผู้เล่นในเกม โดยผู้เล่นต้องส่ง 1 Ether เพื่อเข้าร่วม และต้องมีที่อยู่ (address) ที่ได้รับอนุญาต
- เมื่อผู้เล่นเข้าร่วมจะมีการเพิ่มผู้เล่นในรายชื่อและอัพเดตจำนวนผู้เล่น

### 4. **ฟังก์ชัน `input`**

```solidity
function input(uint choice) public {
    require(numPlayer == 2, "Not enough players");
    require(player_not_played[msg.sender], "You have already played");
    require(choice >= 0 && choice <= 4, "Invalid choice");

    player_choice[msg.sender] = choice;  // บันทึกตัวเลือกของผู้เล่น
    player_not_played[msg.sender] = false;  // กำหนดว่าเลือกแล้ว
    numInput++;  // เพิ่มจำนวนผู้เล่นที่เลือกแล้ว

    if (numInput == 2) {
        _checkWinnerAndPay();  // เมื่อผู้เล่นทั้งสองเลือกแล้วจะคำนวณผล
    }
}
```

- ฟังก์ชันนี้ใช้สำหรับให้ผู้เล่นเลือกตัวเลือกในเกม (0 = Rock, 1 = Paper, 2 = Scissors, 3 = Lizard, 4 = Spock)
- ฟังก์ชันนี้จะตรวจสอบว่าเกมมีผู้เล่นครบ 2 คนหรือไม่ และตรวจสอบว่าผู้เล่นยังไม่ได้เลือกตัวเลือกมาก่อน
- เมื่อผู้เล่นทั้งสองคนเลือกแล้ว จะเรียกฟังก์ชัน `_checkWinnerAndPay` เพื่อคำนวณผลและจ่ายรางวัล

### 5. **ฟังก์ชัน `_checkWinnerAndPay`**

```solidity
function _checkWinnerAndPay() private {
    uint p0Choice = player_choice[players[0]];
    uint p1Choice = player_choice[players[1]];
    address payable account0 = payable(players[0]);
    address payable account1 = payable(players[1]);

    // กฎของเกม Rock, Paper, Scissors, Lizard, Spock
    if ((p0Choice + 1) % 5 == p1Choice) {
        account1.transfer(reward);  // ถ้าผู้เล่น 1 ชนะ ผู้เล่น 1 จะได้รับรางวัล
    } else if ((p1Choice + 1) % 5 == p0Choice) {
        account0.transfer(reward);  // ถ้าผู้เล่น 0 ชนะ ผู้เล่น 0 จะได้รับรางวัล
    } else {
        // ถ้าเสมอ แบ่งรางวัลให้คนละครึ่ง
        account0.transfer(reward / 2);
        account1.transfer(reward / 2);
    }

    // รีเซ็ตค่าให้พร้อมสำหรับรอบถัดไป
    reward = 0;
    numPlayer = 0;
    players = new address  numInput = 0;
}
```

- ฟังก์ชันนี้จะทำการคำนวณผลจากตัวเลือกที่ผู้เล่นเลือก และจ่ายรางวัลให้กับผู้ชนะ
- กฎของเกมใช้ `% 5` เพราะมีตัวเลือก 5 ตัว (Rock, Paper, Scissors, Lizard, Spock)
- ถ้าเสมอ จะมีการแบ่งรางวัลให้กับผู้เล่นทั้งสอง

### 6. **ข้อกำหนด**

- ผู้เล่นต้องมี Ether ในการเข้าร่วมเกม
- ผู้เล่นต้องเลือกหนึ่งในตัวเลือก (Rock, Paper, Scissors, Lizard, Spock)
- มีการตรวจสอบที่อยู่ของผู้เล่นให้เป็นหนึ่งในที่อยู่ที่อนุญาต
- เกมรองรับผู้เล่นได้สูงสุด 2 คนในแต่ละรอบ

---
