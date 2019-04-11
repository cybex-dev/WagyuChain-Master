pragma solidity ^0.4.0;

// The contract takes a perspective of a person owning (an array of) cows.
// A mapping exists of cow owners to an array of cows which
contract WagyuChain {

    struct Cow {
        address id;
        address owner;
        address farm;
        uint rfid;
        uint value;
        uint status;
        uint weight;
        uint height;
        uint length;
        bool isMale;

        address parentMale;
        address parentFemale;

        address abottoir;
        uint[] partsIndex;
        mapping(uint => Part) parts;

        uint[] mealsIndex;
        mapping(uint => Meal) meals;
        uint[] checkupIndex;
        mapping(uint => Checkup) checkups;
    }

    struct Meal {
        uint id;
        byte32 foodType;
        uint quantity;
    }

    struct Part {
        address owner;
        uint id;
        string memory description;
        uint value;
        uint packagingId;
    }

    struct Checkup {
        uint id;
        uint status;
        string memory description;
    }

    address bkbOwner;
    // mapping cow address to cow struct
    mapping(address => Cow) cowMapping;

    event onBornEvent(address owner, uint cowId);                                           //
    event onCowTransferEvent(address cowId, address oldOwner, address newOwner);            //
    event onRelocatedEvent(address cowId, address oldLocation, address newLocation);
    event onStatusUpdate(address cowId, uint oldStatus, uint newStatus);
    event onVeterinarianVisit(address cowAddress, uint status);
    event onMealReceived(address cowAddress);
    event onSlaughteredEvent(address cowId, address abattoir, address slaughteredBy);
    event onPackagedEvent(uint id, uint packagedBy, uint packageStation);
    event onDistributedEvent(uint id, uint retail);
    event onSoldEvent(uint id);

    // Some modifier can be made generic such as isContractOwner & isCowOwner to isOwner(uint realOwnerAddress) but this may not reflect the intended purpose of modifiers
    modifier checkupNotExists(address cowAddress, uint checkupId) {
        require(cowMapping[cowAddress].checkups[checkupId] == 0);
        _;
    }

    modifier mealNotExists(address cowAddress, uint mealId) {
        require(cowMapping[cowAddress].meals[mealId] == 0);
        _;
    }

    modifier isContractOwner() {
        require(msg.sender == BkBOwner);
        _;
    }

    modifier existsCow(address cowAddress) {
        require(cowMapping(cowAddress) != address(0));
        _;
    }

    modifier isCowsOwner(address cowAddress) {
        require(cowMapping(cowAddress).owner == msg.sender, "Error, you are not the cow's owner");
        _;
    }

    modifier notExistsCow(address cowAddress) {
        require(cowMapping(cowAddress).id != address(0), "Sorry, this animal already exists. Please use a different identifier");
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

    constructor() payable {
        BkBOwner = msg.sender;
    }

    function() payable {

    }

    function born(address owner, address cowAddress, address farm, uint rfid, uint value, string memory status, uint weight, uint height, uint length, uint value, bool isMale, address parentMale, address parentFemale) notExistsCow(cowAddress) {
        cowMapping[cowAddress] = Cow(cowAddress, owner, farm, rfid, value, status, weight, height, length, value, isMale, 0, 0, 0, 0);
        emit onBornEvent(owner, id);
    }

    function transfer(address cowAddress, address newOwner) existsCow(cowAddress) isCowsOwner(cowAddress) hasEther(cowMapping(cowAddress).value) {
        msg.sender.call.value(cowMapping(cowAddress).value);
        cowMapping(cowAddress).owner = newOwner;
        emit onCowTransferEvent(cowAddress, msg.sender, newOwner);
    }

    function relocate(address cowAddress, address newLocation) existsCow(cowAddress) isCowsOwner(cowAddress) notSameLocation(cowMapping[cowAddress].farm, newLocation) {
        var oldLocation = cowMapping[cowAddress].farm;
        cowMapping[cowAddress].farm = newLocation;
        emit onRelocatedEvent(cowAddress, oldLocation, newLocation);
    }

    function updateStatus(address cowAddress, uint newStatus) existsCow(cowAddress) isCowsOwner(cowAddress) notSameStatus(cowMapping[cowAddress].status, newStatus) {
        var oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].status = newStatus;
        emit onStatusUpdate(cowAddress, oldStatus, newStatus);
    }

    function mealReceived(address cowAddress, uint id, byte32 foodType, uint quantity) existsCow(cowAddress) isCowsOwner(cowAddress) {
        cowMapping[cowAddress].meals[id] = Meal(id, foodType, quantity);
        cowMapping[cowAddress].mealsIndex.push(id);
        emit onMealReceived(cowAddress);
    }

    function checkupReceived(address cowAddress, uint id, uint status, string memory description) existsCow(cowAddress) isCowsOwner(cowAddress) {
        cowMapping[cowAddress].checkups[id] = Checkup(id, status, description);
        cowMapping[cowAddress].checkupIndex.push(id);
        emit onVeterinarianVisit(cowAddress, status);
    }

    function sendToAbottoir(address cowAddress, address abottoirAddress) existsCow(cowAddress) isCowsOwner(cowAddress) {

    }

    function addCowPart(address cowAddress, uint partId, uint value, string memory description, uint packagingId) isProcessingAbottoir(cowAddress) partNotExist(cowAddress, partId) {

    }

    function transferPart(address cowAddress, uint partId, address newOwner)  existsCow(cowAddress) isCowsOwner(cowAddress) existsPart(cowAddress, partId) {

    }

    function sellPart(address cowAddress, uint partId, address owner) {

    }
}
