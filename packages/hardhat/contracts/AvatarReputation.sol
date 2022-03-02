// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AvatarReputation is ERC721, Ownable { 
    using Strings for string; 
    address public avatarCollection = address(0);
    struct Property { 
        uint256 avatarId;
        uint256 p1; //visibility;  
        uint256 p2; //distinctiveness;
        uint256 p3;// authenticity;
        uint256 p4; //transparency;
        uint256 p5; // consistency; 
        uint256 p6; //vision;  
        uint256 level;  
        uint256 points;        
    }
    Property[] public properties; 
    mapping(uint256 => uint256) avatarToThis; 
    constructor() public ERC721("FDS AvatarReputation", "Avatar Reputation")
    {    
    }  

    function setMinter(address newMinter) public {
    }
    function setAvatarCollection(address _avatarCollection) external
    {    
        require(owner()==msg.sender,"!r");
        //require(avatarCollection==address(0), "already set"); 
        avatarCollection = _avatarCollection; 
    }
    function create(uint256 avatarId, address to) public returns (uint256)
    {
        require(avatarToThis[avatarId]==0,"Avatar Has This Set");
        require(msg.sender==avatarCollection, "!collection");

        uint256 newId = properties.length;
        //uint256 random = _random(randomness);
        // always start with stats from 1 to 10 
        /*uint256 visibility      = 0; //1 + (random % 100) % 10;
        uint256 distinctiveness = 0; //1 + ((random % 10000) / 100 ) % 10;
        uint256 authenticity    = 0; //1 + ((random % 1000000) / 10000 ) % 10;
        uint256 transparency    = 0; //1 + ((random % 100000000) / 1000000 ) % 10;
        uint256 consistency     = 0; //1 + ((random % 10000000000) / 100000000 ) % 10;
        uint256 vision          = 0; //1 + ((random % 1000000000000) / 10000000000) % 10;
        uint256 reputationpoints = 0;*/

        properties.push(
            Property(
                avatarId, 
                0,//visibility,
                0,//distinctiveness,
                0,//authenticity,
                0,//transparency,
                0,//consistency,
                0,//vision,
                0,
                0 //reputationpoints
            )
        );
        _safeMint(to, newId);
        avatarToThis[avatarId] = newId;
        return newId; 
    }
 
    function _random(bytes32 input) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, input, block.timestamp, blockhash(block.number-1))));
    }
    function getInfo(uint256 tokenId) public view returns (Property memory)
    {
        return  properties[tokenId];
    }
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function getLevel(uint256 tokenId) public view returns (uint256) {
        return sqrt(properties[tokenId].level);
    }
    function upgrade(uint256 tokenId,  
            uint256 data /*
            uint256 visibility,
            uint256 distinctiveness,
            uint256 authenticity,
            uint256 transparency,
            uint256 consistency,
            uint256 vision*/) 
            public 
    {
        require(_isApprovedOrOwner(tokenId),"!approved");  

        properties[tokenId].p1 += (data % 100) % 10;
        properties[tokenId].p2 += ((data % 10000) / 100) % 10;
        properties[tokenId].p3 += ((data % 1000000) / 10000) % 10;
        properties[tokenId].p4 += ((data % 100000000) / 1000000) % 10;
        properties[tokenId].p5 += ((data % 10000000000)/ 100000000) % 10;
        properties[tokenId].p6 += ((data % 1000000000000)/ 10000000000) % 10;

        properties[tokenId].level  += 1;
        properties[tokenId].points += calculate_exp(properties[tokenId].p1,  
                                                    properties[tokenId].p2, 
                                                    properties[tokenId].p3, 
                                                    properties[tokenId].p4, 
                                                    properties[tokenId].p5, 
                                                    properties[tokenId].p6);
/*                                                    
        require(_isApprovedOrOwner(tokenId),"!approved"); 
        uint available_skillpoints = properties[tokenId].points; // how much avatar can spend
        uint skillpoints = visibility + distinctiveness + authenticity + transparency + consistency + vision; 
        require(skillpoints<=available_skillpoints,"not enough skill points");

        uint cost = calculate_exp(visibility, distinctiveness, authenticity, transparency, consistency, vision);
        
        properties[tokenId].visibility += visibility;
        properties[tokenId].distinctiveness += distinctiveness;
        properties[tokenId].authenticity += authenticity;
        properties[tokenId].transparency += transparency;
        properties[tokenId].consistency += consistency;
        properties[tokenId].vision += vision;

        properties[tokenId].reputation += cost;
        properties[tokenId].points -= skillpoints; */
    }
    function calc(uint score) public pure returns (uint) {
        if (score <= 12) {
            return score;
        } else {
            return ((score-2)**2)/8;
        }
    }
    function calculate_exp(uint _str, uint _dex, uint _const, uint _int, uint _wis, uint _cha) public pure returns (uint) {
        return calc(_str)+calc(_dex)+calc(_const)+calc(_int)+calc(_wis)+calc(_cha);
    }

    function _isApprovedOrOwner(uint256 tokenId) internal view returns (bool) {
        return getApproved(tokenId) == msg.sender || ownerOf(tokenId) == msg.sender || msg.sender == avatarCollection;
    }
}
