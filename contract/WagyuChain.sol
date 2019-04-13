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
        address vetinarian;
        bytes32 rfid;
        uint value;
        uint status;
        uint[] cowDims; // weight, height, length;
        bool isMale;
        bool forSale;

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
        string foodType;
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
        string status;
        string description;
    }

    address bkbOwner;
    // mapping cow address to cow struct
    address[] public cowIndex;
    mapping(address => Cow) public cowMapping;

    event onBornEvent(address owner, address cowId);                                           //
    event onCowTransferEvent(address cowId, address oldOwner, address newOwner);            //
    event onRelocatedEvent(address cowId, address oldLocation, address newLocation);
    event onStatusUpdate(address cowId, uint oldStatus, uint newStatus);
    event onVeterinarianVisit(address cowAddress, string status);
    event onSlaughteredEvent(address cowId, address abattoir, address slaughteredBy);
    event onPackagedEvent(address cowAddress, uint partId, address packagedBy, uint packageStation);
    event onDistributedEvent(address cowAddress, uint partId, address recieveCentre);
    event onSoldEvent(address cowAddress, uint partId);
    event onCowForSale(address cowAddress, bool isForSale);

    modifier isProcessingAbattoir(address cowAddress) {
        require(cowMapping[cowAddress].abattoir == msg.sender, "Invalid processing abattoir");
        _;
    }

    modifier partNotExist(address cowAddress, uint partId) {
        require(cowMapping[cowAddress].parts[partId].id != partId);
        _;
    }

    modifier isContractOwner() {
        require(msg.sender == bkbOwner);
        _;
    }

    modifier existsCow(address cowAddress) {
        require(cowMapping[cowAddress].id == cowAddress);
        _;
    }

    modifier isCowsOwner(address cowAddress) {
        require(cowMapping[cowAddress].owner == msg.sender, "You are not the cow's owner");
        _;
    }

    modifier notExistsCow(address cowAddress) {
        require(cowMapping[cowAddress].id == address(0), "Cow already registered");
        _;
    }

    modifier hasEther(uint value) {
        require(msg.value == value, "Insufficient funds");
        _;
    }

    modifier notSameLocation(address oldLocation, address newLocation) {
        require(oldLocation != newLocation, "Locations cannot be the same");
        _;
    }

    modifier partNotSold(address cowAddress, uint partId) {
        require(!cowMapping[cowAddress].parts[partId].sold, "Part already sold");
        _;
    }

    modifier checkupNotExists(address cowAddress, uint checkupId) {
        require(cowMapping[cowAddress].checkups[checkupId].id == 0, "Checkup record already exists");
        _;
    }

    modifier mealNotExists(address cowAddress, uint mealId) {
        require(cowMapping[cowAddress].meals[mealId].id == 0, "Meal record already exists");
        _;
    }

    modifier existsPart(address cowAddress, uint partId) {
        require(cowMapping[cowAddress].parts[partId].id != 0, "Part does not exist");
        _;
    }

    modifier isCowForSale(address cowAddress) {
        require(cowMapping[cowAddress].forSale, "Cow is not for sale");
        _;
    }

    modifier checkParentOffspring(address offspring, address parent1, address parent2) {
        require(parent1 != parent2 && offspring != parent2 && offspring != parent1, "Parents/offspring have same ID");
        _;
    }

    modifier notSameVet(address cowAddress, address newVetinarian) {
        require(cowMapping[cowAddress].vetinarian != newVetinarian, "Vetinarians cannot be the same");
        _;
    }

    modifier isCowsVetinarian(address cowAddress) {
        require(cowMapping[cowAddress].vetinarian == msg.sender, "You are not the cow's vet");
        _;
    }

    modifier canTransfer(address cowAddress) {
        require(cowMapping[cowAddress].status != uint(Status.SLAUGHTERED), "Cow already slaughtered");
        _;
    }

    modifier canSlaughter(address cowAddress) {
        require(cowMapping[cowAddress].status != uint(Status.SLAUGHTERED), "Cow ready for slaughter");
        _;
    }

    constructor() public payable {
        bkbOwner = msg.sender;
    }

    function() external payable {

    }

    function setCowMarketStatus(address cowAddress, bool isForSale) public existsCow(cowAddress) isCowsOwner(cowAddress) canTransfer(cowAddress) {
        cowMapping[cowAddress].forSale = isForSale;
        emit onCowForSale(cowAddress, isForSale);
    }

    function setStatus(address cowAddress, uint newStatus) public existsCow(cowAddress) isCowsOwner(cowAddress) {
        uint oldStatus = cowMapping[cowAddress].status;
        cowMapping[cowAddress].status = newStatus;
        emit onStatusUpdate(cowAddress, oldStatus, newStatus);
    }

    function born(address cowAddress, address _farm, address _vetinarian, bytes32 _rfid, uint _value, uint[] memory _cowDims, bool _isMale, address[] memory parents, address abattoirAddress) public notExistsCow(cowAddress) checkParentOffspring(cowAddress, parents[1], parents[0])  {

        cowMapping[cowAddress] = Cow({
            id: cowAddress,
            owner: msg.sender,
            farm: _farm,
            vetinarian: _vetinarian,
            rfid: _rfid,
            value: _value,
            status: uint(Status.CALF),
            cowDims: _cowDims,
            isMale: _isMale,
            forSale: false,
            parentMale: parents[0],
            parentFemale: parents[1],
            abattoir: abattoirAddress,
            partsIndex: new uint[](0),
            mealsIndex: new uint[](0),
            checkupIndex: new uint[](0)
            });
        cowIndex.push(cowAddress);
        emit onBornEvent(msg.sender, cowAddress);
    }

    function setVetinarian(address cowAddress, address newVetinarian) public existsCow(cowAddress) isCowsOwner(cowAddress) notSameVet(cowAddress, newVetinarian) canTransfer(cowAddress) {
        cowMapping[cowAddress].vetinarian = newVetinarian;
    }

    function transfer(address cowAddress, address newOwner) public payable existsCow(cowAddress) isCowForSale(cowAddress) hasEther(cowMapping[cowAddress].value) canTransfer(cowAddress) {
        cowMapping[cowAddress].owner.call.value(cowMapping[cowAddress].value);
        cowMapping[cowAddress].owner = newOwner;
        emit onCowTransferEvent(cowAddress, msg.sender, newOwner);
    }

    function isForSale(address cowAddress) public view existsCow(cowAddress) canTransfer(cowAddress) returns (bool) {
        return cowMapping[cowAddress].forSale;
    }

    function relocate(address cowAddress, address newLocation) public existsCow(cowAddress) isCowsOwner(cowAddress) notSameLocation(cowMapping[cowAddress].farm, newLocation) canTransfer(cowAddress) {
        address oldLocation = cowMapping[cowAddress].farm;
        cowMapping[cowAddress].farm = newLocation;
        emit onRelocatedEvent(cowAddress, oldLocation, newLocation);
    }

    function mealReceived(address cowAddress, uint id, string memory foodType, uint quantity) public existsCow(cowAddress) isCowsOwner(cowAddress) mealNotExists(cowAddress, id) canTransfer(cowAddress) {
        cowMapping[cowAddress].meals[id] = Meal(id, foodType, quantity);
        cowMapping[cowAddress].mealsIndex.push(id);
    }

    function checkupReceived(address cowAddress, uint id, string memory status, string memory description) public existsCow(cowAddress) isCowsVetinarian(cowAddress) checkupNotExists(cowAddress, id) canTransfer(cowAddress) {
        cowMapping[cowAddress].checkups[id] = Checkup(id, status, description);
        cowMapping[cowAddress].checkupIndex.push(id);
        emit onVeterinarianVisit(cowAddress, status);
    }

    function sendToAbattoir(address cowAddress) public existsCow(cowAddress) isCowsOwner(cowAddress) canSlaughter(cowAddress) {
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

    function addCowPart(address worker, uint packaging, address cowAddress, uint partId, bytes32 rfid, uint value, string memory description) public existsCow(cowAddress) isProcessingAbattoir(cowAddress) partNotExist(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId] = Part(cowAddress, partId, rfid, description, value, packaging, false);
        cowMapping[cowAddress].partsIndex.push(partId);
        emit onPackagedEvent(cowAddress, partId, worker, packaging);
    }

    function transferPart(address cowAddress, uint partId, address newOwner) public payable existsCow(cowAddress) existsPart(cowAddress, partId) hasEther(cowMapping[cowAddress].parts[partId].value) {
        cowMapping[cowAddress].owner.call.value(cowMapping[cowAddress].parts[partId].value);
        cowMapping[cowAddress].parts[partId].owner = newOwner;
        emit onDistributedEvent(cowAddress, partId, newOwner);
    }

    function buyPart(address cowAddress, uint partId, address newOwner) public existsCow(cowAddress) existsPart(cowAddress, partId) partNotSold(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId].sold = true;
        cowMapping[cowAddress].parts[partId].owner = newOwner;
        cowMapping[cowAddress].owner.call.value(cowMapping[cowAddress].parts[partId].value);
        emit onSoldEvent(cowAddress, partId);
    }

    function setPartValue(address cowAddress, uint partId, uint newValue) public isCowsOwner(cowAddress) existsPart(cowAddress, partId) {
        cowMapping[cowAddress].parts[partId].value = newValue;
    }
}