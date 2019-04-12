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
        bytes32 description;
        uint value;
        uint packagingId;
        bool sold;
    }

    struct Checkup {
        uint id;
        uint status;
        bytes32 description;
    }

    address bkbOwner;
    // mapping cow address to cow struct
    address[] public cowIndex;
    mapping(address => Cow) public cowMapping;

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

    modifier isProcessingAbattoir(address cowAddress) {
        assert(cowMapping[cowAddress].abattoir == msg.sender);
        _;
    }

    modifier partNotExist(address cowAddress, uint partId) {
        assert(cowMapping[cowAddress].parts[partId].id != partId);
        _;
    }

    modifier isContractOwner() {
        assert(msg.sender == bkbOwner);
        _;
    }

    modifier existsCow(address cowAddress) {
        assert(cowMapping[cowAddress].id == cowAddress);
        _;
    }

    modifier isCowsOwner(address cowAddress) {
        assert(cowMapping[cowAddress].owner == msg.sender);
        _;
    }

    modifier notExistsCow(address cowAddress) {
        assert(cowMapping[cowAddress].id != address(0));
        _;
    }

    modifier hasEther(uint value) {
        assert(msg.value == value);
        _;
    }

    modifier notSameLocation(address oldLocation, address newLocation) {
        assert(oldLocation != newLocation);
        _;
    }

    modifier partNotSold(address cowAddress, uint partId) {
        assert(!cowMapping[cowAddress].parts[partId].sold);
        _;
    }

    modifier checkupNotExists(address cowAddress, uint checkupId) {
        assert(cowMapping[cowAddress].checkups[checkupId].id != 0);
        _;
    }

    modifier mealNotExists(address cowAddress, uint mealId) {
        assert(cowMapping[cowAddress].meals[mealId].id == 0);
        _;
    }

    modifier existsPart(address cowAddress, uint partId) {
        assert(cowMapping[cowAddress].parts[partId].id != 0);
        _;
    }

    constructor() public payable {
        bkbOwner = msg.sender;
    }

    function() external payable {

    }

    function setStatus(address cowAddress, uint newStatus) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        uint oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].status = newStatus;
        emit onStatusUpdate(cowAddress, oldStatus, newStatus);
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

    function mealReceived(address cowAddress, uint id, bytes32 foodType, uint quantity) public existsCow(cowAddress) isCowsOwner(cowAddress) mealNotExists(cowAddress, id) {
        cowMapping[cowAddress].meals[id] = Meal(id, foodType, quantity);
        cowMapping[cowAddress].mealsIndex.push(id);
        emit onMealReceived(cowAddress);
    }

    function checkupReceived(address cowAddress, uint id, uint status, bytes32 description) public existsCow(cowAddress) isCowsOwner(cowAddress) checkupNotExists(cowAddress, id){
        cowMapping[cowAddress].checkups[id] = Checkup(id, status, description);
        cowMapping[cowAddress].checkupIndex.push(id);
        emit onVeterinarianVisit(cowAddress, status);
    }

    function sendToAbattoir(address cowAddress) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        uint oldStatus = cowMapping[cowAddress].status;
        emit onRelocatedEvent(cowAddress, cowMapping[cowAddress].farm, cowMapping[cowAddress].abattoir);
        emit onStatusUpdate(cowAddress, oldStatus, uint(Status.SLAUGHTER_READY));
    }

    function slaughtered(address cowAddress, address butcher) public existsCow(cowAddress) isProcessingAbattoir(cowMapping[cowAddress].abattoir) {
        uint oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].status = uint(Status.SLAUGHTERED);
        emit onSlaughteredEvent(cowAddress, cowMapping[cowAddress].abattoir, butcher);
        emit onStatusUpdate(cowAddress, oldStatus, uint(Status.SLAUGHTERED));
    }

    function addCowPart(address worker, uint packaging, address cowAddress, uint partId, bytes32 rfid, uint value, bytes32 description) public existsCow(cowAddress) isProcessingAbattoir(cowAddress) partNotExist(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId] = Part(cowAddress, partId, rfid, description, value, packaging, false);
        cowMapping[cowAddress].partsIndex.push(partId);
        emit onPackagedEvent(cowAddress, partId, worker, packaging);
    }

    function transferPart(address cowAddress, uint partId, address newOwner) public payable existsCow(cowAddress) isCowsOwner(cowAddress) existsPart(cowAddress, partId) hasEther(cowMapping[cowAddress].parts[partId].value) {
        cowMapping[cowAddress].parts[partId].owner = newOwner;
        msg.sender.call.value(cowMapping[cowAddress].parts[partId].value);
        emit onDistributedEvent(cowAddress, partId, newOwner);
    }

    function sellPart(address cowAddress, uint partId, address newOwner) public existsCow(cowAddress) isCowsOwner(cowAddress) existsPart(cowAddress, partId) partNotSold(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId].sold = true;
        cowMapping[cowAddress].parts[partId].owner = newOwner;
        msg.sender.call.value(cowMapping[cowAddress].parts[partId].value);
        emit onSoldEvent(cowAddress, partId);
    }

    function setPartValue(address cowAddress, uint partId, uint newValue) public isCowsOwner(cowAddress) existsPart(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId].value = newValue;
    }
}