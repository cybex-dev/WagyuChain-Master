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

    event onBornEvent(address owner, address cowId);                                           //
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

    function getCowTag(address cowAddress) public view existsCow(cowAddress) isCowsOwner(cowAddress) returns (bytes32){
        return cowMapping[cowAddress].rfid;
    }

    function getCowPartTag(address cowAddress, uint partId) public view existsCow(cowAddress) existsPart(cowAddress, partId) isCowPartOwner(cowAddress, partId) returns (bytes32) {
        return cowMapping[cowAddress].parts[partId].rfid;
    }

    function getCowPartValue(address cowAddress, uint partId) public view existsCow(cowAddress) existsPart(cowAddress, partId) isCowPartOwner(cowAddress, partId) returns (uint) {
        return cowMapping[cowAddress].parts[partId].value;
    }

    function getCowPartOwner(address cowAddress, uint partId) public view existsCow(cowAddress) isCowsOwner(cowAddress) existsPart(cowAddress, partId) returns (address) {
        return cowMapping[cowAddress].parts[partId].owner;
    }

    function getCowInfo(address cowAddress) existsCow(cowAddress) public view isCowsOwner(cowAddress) returns (address, address, address, bytes32, uint, uint, uint, uint, uint, bool) {
        Cow memory cow = cowMapping[cowAddress];
        return (cow.id, cow.owner, cow.farm, cow.rfid, cow.value, cow.status, cow.weight, cow.height, cow.length, cow.isMale);
    }

    function getAllCowIds(address cowAddress) public view existsCow(cowAddress) isContractOwner() returns (address[] memory) {
        return cowIndex;
    }

    function getAllCowPartsIds(address cowAddress) public view existsCow(cowAddress) isCowsOwner(cowAddress) returns (uint[] memory)  {
        return cowMapping[cowAddress].partsIndex;
    }

    function getCowPart(address cowAddress, uint partId) public view existsCow(cowAddress) isCowsOwner(cowAddress) existsPart(cowAddress, partId) returns (address, uint, bytes32, string memory, uint, uint, bool) {
        Part memory part = cowMapping[cowAddress].parts[partId];
        return (part.owner, part.id, part.rfid, part.description, part.value, part.packagingId, part.sold);
    }

    function isCowPartSold(address cowAddress, uint partId) public view existsCow(cowAddress) existsPart(cowAddress, partId) returns (bool){
        return cowMapping[cowAddress].parts[partId].sold;
    }

    function getCowStatus(address cowAddress) public view existsCow(cowAddress)  isCowsOwner(cowAddress) returns (uint) {
        return uint(cowMapping[cowAddress].status);
    }

    function getCowCheckupIds(address cowAddress) public view existsCow(cowAddress) isCowsOwner(cowAddress) returns (uint[] memory) {
        return cowMapping[cowAddress].checkupIndex;
    }

    function getCowCheckup(address cowAddress, uint checkupId) public view existsCow(cowAddress) isCowsOwner(cowAddress) checkupExists(cowAddress, checkupId) returns (uint, uint, string memory) {
        Checkup memory checkup = cowMapping[cowAddress].checkups[checkupId];
        return (checkup.id, checkup.status, checkup.description);
    }

    function getCowMealIds(address cowAddress) existsCow(cowAddress) public view isCowsOwner(cowAddress) returns (uint[] memory) {
        return cowMapping[cowAddress].mealsIndex;
    }

    function getCowMeal(address cowAddress, uint mealId) existsCow(cowAddress) public view isCowsOwner(cowAddress) mealExists(cowAddress, mealId) returns (uint, bytes32, uint ) {
        Meal memory meal = cowMapping[cowAddress].meals[mealId];
        return (meal.id, meal.foodType, meal.quantity);
    }

    function setStatus(address cowAddress, uint newStatus) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        uint oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].status = newStatus;
        emit onStatusUpdate(cowAddress, oldStatus, newStatus);
    }

    function setAbattoir(address cowAddress, address _abattoir) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        cowMapping[cowAddress].abattoir = _abattoir;
    }

    function born(address _owner, address cowAddress, address _farm, bytes32 _rfid, uint _value, uint _weight, uint _height, uint _length, bool _isMale, address _parentMale, address _parentFemale, address abattoirAddress) public notExistsCow(cowAddress) {
        cowMapping[cowAddress] = Cow({
            id: cowAddress,
            owner: _owner,
            farm: _farm,
            rfid: _rfid,
            value: _value,
            status: uint(Status.CALF),
            weight: _weight,
            height: _height,
            length: _length,
            isMale: _isMale,
            parentMale: _parentMale,
            parentFemale: _parentFemale,
            abattoir: abattoirAddress,
            partsIndex: new uint[](0),
            mealsIndex: new uint[](0),
            checkupIndex: new uint[](0)
            });
        cowIndex.push(cowAddress);
        emit onBornEvent(_owner, cowAddress);
    }

    function transfer(address cowAddress, address newOwner) public payable existsCow(cowAddress) isCowsOwner(cowAddress) hasEther(cowMapping[cowAddress].value) {
        msg.sender.call.value(cowMapping[cowAddress].value);
        cowMapping[cowAddress].owner = newOwner;
        emit onCowTransferEvent(cowAddress, msg.sender, newOwner);
    }

    function relocate(address cowAddress, address newLocation) public existsCow(cowAddress) isCowsOwner(cowAddress) notSameLocation(cowMapping[cowAddress].farm, newLocation) {
        address oldLocation = cowMapping[cowAddress].farm;
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
        uint oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].abattoir = abattoirAddress;
        emit onRelocatedEvent(cowAddress, cowMapping[cowAddress].farm, abattoirAddress);
        emit onStatusUpdate(cowAddress, oldStatus, uint(Status.SLAUGHTER_READY));
    }

    function slaughtered(address cowAddress, address abattoir, address butcher) public existsCow(cowAddress) isProcessingAbattoir(abattoir) {
        uint oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].status = uint(Status.SLAUGHTERED);
        emit onSlaughteredEvent(cowAddress, abattoir, butcher);
        emit onStatusUpdate(cowAddress, oldStatus, uint(Status.SLAUGHTERED));
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
        cowMapping[cowAddress].parts[partId].owner = newOwner;
        emit onSoldEvent(cowAddress, partId);
    }

    function setPartValue(address cowAddress, uint partId, uint newValue) public isCowsOwner(cowAddress) existsPart(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId].value = newValue;
    }
}
