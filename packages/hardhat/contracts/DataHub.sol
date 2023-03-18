// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DataHub is Ownable, ReentrancyGuard, AccessControl  {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 private constant FEE_PRECISION = 1e5;  
    uint256 public marketFee = 1000; // 1%
    uint256 public minListingFee = 1000000 gwei; // min listing fee - 0.0001000 ETH
    uint256 public feesCollected = 0;
    uint256 public inEscrow = 0;
    bytes32 public constant ROLE_REPORTER = keccak256("ROLE_REPORTER");

    // subscription request
    struct SubRequest {
        bytes32 fdpBuyerNameHash;
        address buyer;
        bytes32 subHash; //which subscription;
        bytes32 requestHash; // this is needed when
    }
    // active Bid
    struct ActiveBid {
        address seller;
        bytes32 requestHash;
    }
    // subscription items
    struct SubItem {
        bytes32 subHash;  // what subscription you are entitled to
        bytes32 unlockKeyLocation; // where is your key
        uint256 validTill; // until it is valid 
    }
    struct User {
        // who wants to subscribe to what
        SubRequest[] subRequests;
        mapping(bytes32 => uint256) subRequestIds;
        // what is user subscribed to
        SubItem[] subItems;
        mapping(bytes32 => uint256) subItemIds;

        ActiveBid[] activeBids;
        mapping(bytes32 => uint256) activeBidIds;

        bytes32[] listedSubs; // everything user listed 
    }
    mapping(address => User) users;
    mapping(address => address) userToPortable;    

    struct Category {
        uint64[]     subIdxs;
    }
    mapping(bytes32 => Category) categories; // where is category in categories array

    // Sub listings
    struct Sub {
        bytes32 subHash;
        bytes32 fdpSellerNameHash; //
        address seller;
        bytes32 swarmLocation; // metadata location
        uint256 price;
        bool    active; // is subscription active
        uint256 earned;  
        uint32  bids;
        uint32  sells;
        uint32  reports; 
        uint16  daysValid;
    }
    Sub[] public  subscriptions;
    mapping(bytes32 => uint256) public subscriptionIds; 

    struct SubInfo {
        mapping(address => uint256) perSubscriberBalance; // balance per subscriber
        address[] subscribers; 
    }
    mapping(bytes32 => SubInfo) subInfos; // where is sub in subscriptions array    

    constructor() {
    }

    receive() external payable {}

    function getUserStats(address addr) public view returns (uint numSubRequests, uint numSubItems, uint numActiveBids, uint numListedSubs) {
        numSubRequests = users[addr].subRequests.length;
        numSubItems = users[addr].subItems.length;
        numActiveBids = users[addr].activeBids.length;
        numListedSubs = users[addr].listedSubs.length;
    }
    function setPortableAddress(address addr) public {
        userToPortable[msg.sender] = addr;
    }
    function getPortableAddress(address addr) public view returns (address) {
        return userToPortable[addr];
    }    
    function getFee(uint256 _fee, uint256 amount) public pure returns (uint256) {
        return (amount * _fee) / FEE_PRECISION;
    }
    function setFee(uint256 newFee) onlyOwner public  {
        marketFee = newFee; 
    }
    function setListingFee(uint256 newListingFee) onlyOwner public  {
        minListingFee = newListingFee; 
    }      
    function getCategory(bytes32 category) public view returns (Category memory) {
        return categories[category];
    }
    function getSubs() public view returns (Sub[] memory) {
        return subscriptions;
    }
    function getSubByIndex(uint index) public view returns (Sub memory) {
        return subscriptions[index];
    }
    function getSubBy(bytes32 subHash) public view returns (Sub memory) {
        return subscriptions[subscriptionIds[subHash]-1];
    }
    function getSubRequestAt(address addr, uint index) public view returns (SubRequest memory) {
        return users[addr].subRequests[index];
    }
    function getSubItemAt(address addr, uint index) public view returns (SubItem memory) {
        return users[addr].subItems[index];
    }
    function getActiveBidAt(address addr, uint index) public view returns (ActiveBid memory) {
        return users[addr].activeBids[index];
    }    
    // todo remove 
    function getSubItems(address addr, uint start, uint length) public view returns (SubItem[] memory items, uint last) {
        // either we  iterate through all items and return only those that are active
        // or we return all items and let the client filter them
        // iterate through active subItems
        items = new SubItem[](length);
        uint count = 0;
        last = 0; // init to 0
        
        for (uint i = start; i < users[addr].subItems.length; i++) {
            if(block.timestamp < users[addr].subItems[i].validTill) {
                if(count < length)
                {
                   items[count] = users[addr].subItems[i];
                   //items.push(users[addr].subItems[i]);
                   ++count;
                   last = i;
                } else 
                    break;
            }
        }
        //return items;
    }
    function getSubItemBy(address addr, bytes32 subHash) public view returns (SubItem memory) {
        // check if subHash subItem is active
        require(block.timestamp <= users[addr].subItems[users[addr].subItemIds[subHash]-1].validTill, "SubItem expired");
        return users[addr].subItems[users[addr].subItemIds[subHash]-1];
    }
    function getAllSubItems(address addr) public view returns (SubItem[] memory) {
        // TODO return non active without keyLockLocation
        SubItem[] memory items = new SubItem[](users[addr].subItems.length);
        for (uint i = 0; i < users[addr].subItems.length; i++) {
            items[i] = users[addr].subItems[i];
            if(block.timestamp > items[i].validTill) {
                items[i].unlockKeyLocation = bytes32(0);
            }
        }
        return items; //users[addr].subItems;
    }
    function getListedSubs(address addr) public view returns (bytes32[] memory) {
        return users[addr].listedSubs;
    }
    function getActiveBids(address addr) public view returns (ActiveBid[] memory) {
        return users[addr].activeBids;
    }
    function getSubRequestByHash(address addr, bytes32 requestHash) public view returns (SubRequest memory) {
        return users[addr].subRequests[users[addr].subRequestIds[requestHash]-1];
    }
    function getActiveBidsByHash(address addr, bytes32 requestHash) public view returns (ActiveBid memory) {
        return users[addr].activeBids[users[addr].activeBidIds[requestHash]-1];
    }
    function getSubRequests(address addr) public view returns (SubRequest[] memory) {
        return users[addr].subRequests;
    }
    function getSubSubscribers(bytes32 subHash) public view returns (address[] memory) {
        return subInfos[subHash].subscribers;
    }
    function getSubInfoBalance(bytes32 subHash, address forAddress) public view returns (uint256) {
        return subInfos[subHash].perSubscriberBalance[forAddress];
    }
    function enableSub(bytes32 subHash, bool active) public {
        require(subscriptionIds[subHash] != 0, "No Sub"); // must exists
        Sub storage s = subscriptions[subscriptionIds[subHash] - 1]; 
        require(s.seller == msg.sender, "Not Seller"); // only seller can enable subscription
        require(s.reports<4, "Too many reports"); // only seller can enable subscription

        s.active = active;
    }
    function reportSub(bytes32 subHash) public {
        require(hasRole(ROLE_REPORTER, msg.sender),"Not Reporter");
        require(subscriptionIds[subHash] != 0, "No Sub"); // must exists
        Sub storage s = subscriptions[subscriptionIds[subHash] - 1]; 
        s.reports = s.reports + 1;
        if(s.reports >= 3) {
            s.active = false;
        }
    }
    // Market to sell encrypted swarmLocation
    function listSub(bytes32 fdpSellerNameHash, bytes32 dataSwarmLocation, uint price, bytes32 category, address podAddress, uint16 daysValid) public payable {
        //bytes32 subHash = keccak256(abi.encode(msg.sender, fdpSeller, dataSwarmLocation, price, category, podIndex));
        require(msg.value>=minListingFee, "minFee"); // sent value must be equal to price
        require(daysValid>=1 && daysValid<=365, "daysValid"); // must not exists

        bytes32 subHash = keccak256(abi.encode(msg.sender, fdpSellerNameHash, podAddress));// user can list same pod only once
        require(subscriptionIds[subHash] == 0, "SubExists"); // must not exists

        Sub memory s = Sub(subHash, fdpSellerNameHash, msg.sender, dataSwarmLocation, price, true, 0, 0, 0, 0, daysValid);
        
        subscriptions.push(s);
        subscriptionIds[subHash] = subscriptions.length; // will point to 1 more than index

        Category storage c = categories[category];
        c.subIdxs.push(uint64(subscriptions.length) - 1); // point to index

        User storage seller = users[msg.sender];
        seller.listedSubs.push(subHash);

        feesCollected+=msg.value;
    }
    function bidSub(bytes32 subHash, bytes32 fdpBuyerNameHash) public nonReentrant payable {
        // marketplace does not require user to be registred with smail -- TODO on front end and check 
        // require(users[msg.sender].key != bytes32(0), "Not reg"); // user can not receive encrypted data
        require(subscriptionIds[subHash] != 0, "No Sub"); // must exists
        Sub storage s = subscriptions[subscriptionIds[subHash] - 1]; 

        require(s.active, "Inactive"); // must be active
        require(msg.value==s.price, "Value!=price"); // sent value must be equal to price

        User storage seller = users[s.seller];
        bytes32 requestHash = keccak256(abi.encode(msg.sender, subHash, fdpBuyerNameHash)); //, block.timestamp));
        require(seller.subRequestIds[requestHash] == 0, "Req exists");

        s.bids++;

        SubRequest memory sr;
        sr.fdpBuyerNameHash = fdpBuyerNameHash;
        sr.buyer = msg.sender;
        sr.subHash = s.subHash;
        sr.requestHash = requestHash;

        seller.subRequests.push(sr);
        seller.subRequestIds[requestHash] = seller.subRequests.length; // +1 of index
        
        inEscrow += msg.value;

        ActiveBid memory ab;
        ab.requestHash = requestHash;
        ab.seller = s.seller; //msg.sender;

        User storage buyer = users[msg.sender];
        buyer.activeBids.push(ab);      
        buyer.activeBidIds[requestHash] = buyer.activeBids.length; // +1 of index
    }
    // encryptedSecret is podReference encrypited with sharedSecret - podAddress, seller.address, buyer.address, encryptedSecret
    function sellSub(bytes32 requestHash, bytes32 encryptedKeyLocation) public nonReentrant payable {
        User storage seller = users[msg.sender];
        require(seller.subRequestIds[requestHash] != 0, "No Req");

        SubRequest memory br = seller.subRequests[seller.subRequestIds[requestHash]-1];
        require(subscriptionIds[br.subHash] != 0, "No Sub"); // must exists

        Sub storage s = subscriptions[subscriptionIds[br.subHash]-1]; 
        require(msg.sender==s.seller, "Not Sub Seller"); // sent value must be equal to price

        uint256 fee = getFee(marketFee, s.price);
        payable(msg.sender).transfer(s.price-fee);
        inEscrow -= s.price;
        feesCollected += fee;

        s.sells++;
        s.earned += (s.price-fee);

        User storage buyer = users[br.buyer];
        SubItem memory si;
        si.subHash = br.subHash;
        si.unlockKeyLocation = encryptedKeyLocation;
        si.validTill = block.timestamp + (s.daysValid * 86400); //(daysValid * 60*60*24) // days;

        buyer.subItems.push(si);
        buyer.subItemIds[br.subHash] = buyer.subItems.length; // +1 of index (so call subHash -1)

        if(subInfos[br.subHash].perSubscriberBalance[br.buyer]==0) // only add subscriber if not already added
           subInfos[br.subHash].subscribers.push(br.buyer);

        subInfos[br.subHash].perSubscriberBalance[br.buyer] += (s.price-fee);

        // seller removes request from his list
        removeSubRequest(msg.sender, requestHash); // remove from seller 
        removeActiveBid(br.buyer, requestHash);
    }
    // removes active bids from SubRequests of seller and from Active bids of buyer
    function removeUserActiveBid(bytes32 requestHash) public {
        User storage u = users[msg.sender];
        require(u.activeBidIds[requestHash] != 0, "!ab Req");
        ActiveBid memory ab = u.activeBids[u.activeBidIds[requestHash]-1];

        User storage seller = users[ab.seller];
        require(seller.subRequestIds[requestHash] != 0, "!seller Req");

        SubRequest storage br = seller.subRequests[seller.subRequestIds[requestHash]-1];
        require(subscriptionIds[br.subHash] != 0, "!sub");

        Sub memory s = subscriptions[subscriptionIds[br.subHash]-1];
        payable(msg.sender).transfer(s.price);

        removeSubRequest(ab.seller, requestHash); // remove from seller 
        removeActiveBid(msg.sender, requestHash);
    }
    function removeActiveBid(address user, bytes32 requestHash) private {
        User storage u = users[user];
        require(u.activeBidIds[requestHash] != 0, "!ab Req");

        uint256 removeIndex = u.activeBidIds[requestHash] - 1;       
        uint256 lastIndex = u.activeBids.length - 1; // replace removeIndex with last item and pop last item
        if (lastIndex != removeIndex) {
            u.activeBids[removeIndex] = u.activeBids[lastIndex];
            u.activeBidIds[u.activeBids[removeIndex].requestHash] = removeIndex + 1;
        }
        u.activeBids.pop();
        delete u.activeBidIds[requestHash];
    }
    // user can remove subItem from his list if wishes to do so
    function removeSubItem(uint256 index) private {
        User storage u = users[msg.sender];
        require(index < u.subItems.length, "!Index");

        uint256 lastIndex = u.subItems.length - 1;
        if (lastIndex != index) {
            u.subItems[index] = u.subItems[lastIndex];
        }
        u.subItems.pop();
    }
    // remove subRequest from seller needs to return money to bidder 
    function removeSubRequest(address owner, bytes32 requestHash) private {
        User storage u = users[owner]; //msg.sender];
        require(u.subRequestIds[requestHash] != 0, "!Req");

        uint256 removeIndex = u.subRequestIds[requestHash] - 1;
        uint256 lastIndex = u.subRequests.length - 1; // replace removeIndex with last item and pop last item
        if (lastIndex != removeIndex) {
            u.subRequests[removeIndex] = u.subRequests[lastIndex];
            u.subRequestIds[u.subRequests[lastIndex].requestHash] = removeIndex + 1;
        }
        u.subRequests.pop();
        delete u.subRequestIds[requestHash];
        //delete u.subRequests[lastIndex];
    }
    function fundsBalance() public view returns (uint256) {
        return address(this).balance;
    }    
    function fundsTransfer() onlyOwner public payable {
        payable(msg.sender).transfer((address(this).balance-inEscrow));
    }
    function release(address token, uint amount) public virtual {
        SafeERC20.safeTransfer(IERC20(token), owner(), amount);
    }
}
