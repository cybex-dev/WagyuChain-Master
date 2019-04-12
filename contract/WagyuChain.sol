pragma solidity ^0.5.7;

// The contract takes a perspective of a person owning (an array of) cows.
// A mapping exists of cow owners to an array of cows which
contract WagyuChain {

    enum Status {
        CALF, ADULT, DIED, DISEASED, SLAUGHTER_READY, SLAUGHTERED
    }

    struct Cow {
        address id;
        address owner;
        address farm;
        bytes32 rfid;
        uint value;
        uint status;
        uint weight;
        uint height;
        uint length;
        bool isMale;

        address parentMale;
        address parentFemale;

        address abattoir;
        uint[] partsIndex;
        mapping(uint => Part) parts;

        uint[] mealsIndex;
        mapping(uint => Meal) meals;
        uint[] checkupIndex;
        mapping(uint => Checkup) checkups;
    }

    struct Meal {
        uint id;
        bytes32 foodType;
        uint quantity;
    }

    struct Part {
        address owner;
        uint id;
        bytes32 rfid;
        string description;
        uint value;
        uint packagingId;
        bool sold;
    }

    struct Checkup {
        uint id;
        uint status;
        string description;
    }

    address bkbOwner;
    // mapping cow address to cow struct
    address[] cowIndex;
    mapping(address => Cow) cowMapping;

    event onBornEvent(address owner, uint cowId);                                           //
    event onCowTransferEvent(address cowId, address oldOwner, address newOwner);            //
    event onRelocatedEvent(address cowId, address oldLocation, address newLocation);
    event onStatusUpdate(address cowId, uint oldStatus, uint newStatus);
    event onVeterinarianVisit(address cowAddress, uint status);
    event onMealReceived(address cowAddress);
    event onSlaughteredEvent(address cowId, address abattoir, address slaughteredBy);
    event onPackagedEvent(address cowAddress, uint partId, address packagedBy, uint packageStation);
    event onDistributedEvent(address cowAddress, uint partId, address recieveCentre);
    event onSoldEvent(address cowAddress, uint partId);

    // Some modifier can be made generic such as isContractOwner & isCowOwner to isOwner(uint realOwnerAddress) but this may not reflect the intended purpose of modifiers
    modifier checkupNotExists(address cowAddress, uint checkupId) {
        require(cowMapping[cowAddress].checkups[checkupId].id == 0);
        _;
    }

    modifier isProcessingAbattoir(address cowAddress) {
        require(cowMapping[cowAddress].abattoir == msg.sender, "Error, the given abattoir address is not the destined abattoir for this cow.");
        _;
    }

    modifier partNotExist(address cowAddress, uint partId) {
        require(cowMapping[cowAddress].parts[partId].id != partId, "Error, the part does not exist");
        _;
    }

    modifier mealNotExists(address cowAddress, uint mealId) {
        require(cowMapping[cowAddress].meals[mealId].id == 0);
        _;
    }

    modifier isContractOwner() {
        require(msg.sender == bkbOwner);
        _;
    }

    modifier existsCow(address cowAddress) {
        require(cowMapping[cowAddress].id == cowAddress, "Sorry, cow does not exist");
        _;
    }

    modifier isCowsOwner(address cowAddress) {
        require(cowMapping[cowAddress].owner == msg.sender, "Error, you are not the cow's owner");
        _;
    }

    modifier notExistsCow(address cowAddress) {
        require(cowMapping[cowAddress].id != address(0), "Sorry, this animal already exists. Please use a different identifier");
        _;
    }

    modifier hasEther(uint value) {
        require(msg.value == value, "Sorry, you do not have enough funds.");
        _;
    }

    modifier notSameLocation(address oldLocation, address newLocation) {
        require(oldLocation != newLocation, "Error, the old and new destinations cannot be the same");
        _;
    }

    modifier partNotSold(address cowAddress, uint partId) {
        require(!cowMapping[cowAddress].parts[partId].sold, "This item has already been sold, it cannot be sold again.");
        _;
    }

    modifier checkupExists(address cowAddress, uint checkupId) {
        require(cowMapping[cowAddress].checkups[checkupId].id != 0, "Error, checkup record does not exist");
        _;
    }

    modifier mealExists(address cowAddress, uint mealId) {
        require(cowMapping[cowAddress].meals[mealId].id != 0, "Error, meal record does not exist");
        _;
    }

    modifier isCowPartOwner(address cowAddress, uint partId) {
        require(cowMapping[cowAddress].parts[partId].owner == msg.sender, "Sorry, you are not authorized to view this");
        _;
    }

    modifier existsPart(address cowAddress, uint partId) {
        require(cowMapping[cowAddress].parts[partId].id != 0, "Sorry, part not found");
        _;
    }

    constructor() public payable {
        bkbOwner = msg.sender;
    }

    function() external payable {

    }

    function getCowTag(address cowAddress) public existsCow(cowAddress) isCowsOwner(cowAddress) returns (bytes32){
        return cowMapping[cowAddress].rfid;
    }

    function getCowPartTag(address cowAddress, uint partId) public existsCow(cowAddress) existsPart(cowAddress, partId) isCowPartOwner(cowAddress, partId) returns (bytes32) {
        return cowMapping[cowAddress].parts[partId].rfid;
    }

    function getCowPartValue(address cowAddress, uint partId) public existsCow(cowAddress) existsPart(cowAddress, partId) isCowPartOwner(cowAddress, partId) returns (uint) {
        return cowMapping[cowAddress].parts[partId].value;
    }

    function getCowPartOwner(address cowAddress, uint partId) public existsCow(cowAddress) isCowsOwner(cowAddress) existsPart(cowAddress, partId) returns (address) {
        return cowMapping[cowAddress].parts[partId].owner;
    }

    function getCowInfo(address cowAddress) existsCow(cowAddress) public isCowsOwner(cowAddress) returns (Cow memory cow) {
        return cowMapping[cowAddress];
    }

    function getAllCowIds(address cowAddress) public existsCow(cowAddress) isContractOwner() returns (address[] memory) {
        return cowIndex;
    }

    function getAllCowPartsIds(address cowAddress) public existsCow(cowAddress) isCowsOwner(cowAddress) returns (uint[] memory)  {
        return cowMapping[cowAddress].partsIndex;
    }

    function getCowPart(address cowAddress, uint partId) public existsCow(cowAddress) isCowsOwner(cowAddress) existsPart(cowAddress, partId) returns (Part memory) {
        return cowMapping[cowAddress].parts[partId];
    }

    function isCowPartSold(address cowAddress, uint partId) public existsCow(cowAddress) existsPart(cowAddress, partId) returns (bool){
        return cowMapping[cowAddress].parts[partId].sold;
    }

    function getCowStatus(address cowAddress) existsCow(cowAddress) public isCowsOwner(cowAddress) returns (Status) {
        return cowMapping[cowAddress].status;
    }

    function getCowCheckupIds(address cowAddress) existsCow(cowAddress) public isCowsOwner(cowAddress) returns (uint[] memory) {
        return cowMapping[cowAddress].checkupIndex;
    }

    function getCowCheckup(address cowAddress, uint checkupId) public existsCow(cowAddress) isCowsOwner(cowAddress) checkupExists(cowAddress, checkupId) returns (Checkup memory) {
        return cowMapping[cowAddress].checkups[checkupId];
    }

    function getCowMealIds(address cowAddress) existsCow(cowAddress)  public isCowsOwner(cowAddress) returns (uint[] memory) {
        return cowMapping[cowAddress].mealsIndex;
    }

    function getCowMeal(address cowAddress, uint mealId) existsCow(cowAddress) public isCowsOwner(cowAddress) mealExists(cowAddress, mealId) returns (Meal memory) {
        return cowMapping[cowAddress].meals[mealId];
    }

    function setStatus(address cowAddress, Status newStatus) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        var oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].status = newStatus;
        emit onStatusUpdate(cowAddress, oldStatus, newStatus);
    }

    function setAbattoir(address cowAddress, address _abattoir) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        cowMapping[cowAddress].abattoir = _abattoir;
    }

    function born(address owner, address cowAddress, address farm, bytes32 rfid, uint value, uint weight, uint height, uint length, bool isMale, address parentMale, address parentFemale) public notExistsCow(cowAddress) {
        cowMapping[cowAddress] = Cow(cowAddress, owner, farm, rfid, value, Status.CALF, weight, height, length, value, isMale, 0, 0, 0, 0);
        cowIndex.push(cowAddress);
        emit onBornEvent(owner, cowAddress);
    }

    function transfer(address cowAddress, address newOwner) public existsCow(cowAddress) isCowsOwner(cowAddress) hasEther(cowMapping(cowAddress).value) {
        msg.sender.call.value(cowMapping(cowAddress).value);
        cowMapping(cowAddress).owner = newOwner;
        emit onCowTransferEvent(cowAddress, msg.sender, newOwner);
    }

    function relocate(address cowAddress, address newLocation) public existsCow(cowAddress) isCowsOwner(cowAddress) notSameLocation(cowMapping[cowAddress].farm, newLocation) {
        var oldLocation = cowMapping[cowAddress].farm;
        cowMapping[cowAddress].farm = newLocation;
        emit onRelocatedEvent(cowAddress, oldLocation, newLocation);
    }

    function mealReceived(address cowAddress, uint id, bytes32 foodType, uint quantity) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        cowMapping[cowAddress].meals[id] = Meal(id, foodType, quantity);
        cowMapping[cowAddress].mealsIndex.push(id);
        emit onMealReceived(cowAddress);
    }

    function checkupReceived(address cowAddress, uint id, uint status, string memory description) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        cowMapping[cowAddress].checkups[id] = Checkup(id, status, description);
        cowMapping[cowAddress].checkupIndex.push(id);
        emit onVeterinarianVisit(cowAddress, status);
    }

    function sendToAbattoir(address cowAddress, address abattoirAddress) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        var oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].abattoir = abattoirAddress;
        emit onRelocatedEvent(cowAddress, cowMapping[cowAddress].farm, abattoirAddress);
        emit onStatusUpdate(cowMapping, oldStatus, Status.SLAUGHTER_READY);
    }

    function slaughtered(address cowAddress, address abattoir, address butcher) public existsCow(cowAddress) isProcessingAbattoir(abattoir) {
        var oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].status = Status.SLAUGHTERED;
        emit onSlaughteredEvent(cowAddress, abattoir, butcher);
        emit onStatusUpdate(cowMapping, oldStatus, Status.SLAUGHTERED);
    }

    function addCowPart(address worker, uint packaging, address cowAddress, uint partId, bytes32 rfid, uint value, string memory description) public existsCow(cowAddress) isProcessingAbattoir(cowAddress) partNotExist(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId] = Part(cowAddress, partId, rfid, description, value, packaging, false);
        cowMapping[cowAddress].partsIndex.push(partId);
        emit onPackagedEvent(cowAddress, partId, worker, packaging);
    }

    function transferPart(address cowAddress, uint partId, address newOwner) public existsCow(cowAddress) isCowsOwner(cowAddress) existsPart(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId].owner = newOwner;
        emit onDistributedEvent(cowAddress, partId, newOwner);
    }

    function sellPart(address cowAddress, uint partId, address newOwner) public existsCow(cowAddress) isCowsOwner(cowAddress) existsPart(cowAddress, partId) partNotSold(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId].sold = true;
        emit onSoldEvent(cowAddress, partId);
    }

    function setPartValue(address cowAddress, uint partId, uint newValue) public isCowsOwner(cowAddress) existsPart(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId].value = newValue;
    }
}
