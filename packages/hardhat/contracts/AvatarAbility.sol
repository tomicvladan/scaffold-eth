// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AvatarAbility is ERC721, Ownable { 
    using Strings for string; 
    address public avatarCollection = address(0);
    struct Ability { 
        uint256 avatarId;
        uint256 p1; //strength; 
        uint256 p2; //dexterity;
        uint256 p3; //constitution;
        uint256 p4; //intelligence;
        uint256 p5; //wisdom; 
        uint256 p6; //charisma; 
        uint256 level;  
        uint256 points; 
    }
    Ability[] public abilities;
    mapping(uint256 => uint256) avatarToAbility; 
    constructor() ERC721("FDS AvatarAbility", "Avatar Ability")
    {    
    } 
 
    function setMinter(address newMinter) public {
       // does nothing as anyone can mint Avatar
    }
    function setAvatarCollection(address _avatarCollection) external
    {    
        //require(avatarCollection==address(0), "already set"); 
        require(owner()==msg.sender,"!r");
        avatarCollection = _avatarCollection; 
    }
    function create(uint256 avatarId, address to) public returns (uint256)
    {
        require(avatarToAbility[avatarId]==0,"Avatar Has This Set");
        require(msg.sender==avatarCollection, "!collection");

        uint256 newId = abilities.length; 
        /*
        uint256 random = _random(randomness);
        // always start with stats from 1 to 10 
        uint256 strength     = 0;//1 +  (random % 100) % 20;
        uint256 dexterity    = 0;//1 + ((random % 10000) / 100 ) % 20;
        uint256 constitution = 0;//1 + ((random % 1000000) / 10000 ) % 20;
        uint256 intelligence = 0;//1 + ((random % 100000000) / 1000000 ) % 20;
        uint256 wisdom       = 0;//1 + ((random % 10000000000) / 100000000 ) % 20;
        uint256 charisma     = 0;//1 + ((random % 1000000000000) / 10000000000) % 20;
        //uint256 p7 = 1 + ((random % 10000000000000) / 100000000000) % 20;
        uint256 points = 0; //70 - (strength + dexterity + constitution + intelligence + wisdom + charisma); // be fair and add skill points to unlucky
        */
        abilities.push(
            Ability(
                0,//avatarId,
                0,//strength,
                0,//dexterity,
                0,//constitution,
                0,//intelligence,
                0,//wisdom,
                0,//charisma,
                0,
                0 //points
            )
        );
        _safeMint(to, newId);
        avatarToAbility[avatarId] = newId;
        return newId;
    }

    function _random(bytes32 input) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, input, block.timestamp, blockhash(block.number-1))));
    }
    function getInfo(uint256 tokenId) public view returns (Ability memory)
    {
        return  abilities[tokenId];
    }
    function upgrade(uint256 tokenId,  
            uint256 data/*,
            uint256 strength,
            uint256 dexterity,
            uint256 constitution,
            uint256 intelligence,
            uint256 wisdom,
            uint256 charisma*/)  
            public 
    {
        require(_isApprovedOrOwner(tokenId),"!approved"); 
        abilities[tokenId].p1 += (data % 100) % 10;
        abilities[tokenId].p2 += ((data % 10000) / 100) % 10;
        abilities[tokenId].p3 += ((data % 1000000) / 10000) % 10;
        abilities[tokenId].p4 += ((data % 100000000) / 1000000) % 10;
        abilities[tokenId].p5 += ((data % 10000000000)/ 100000000) % 10;
        abilities[tokenId].p6 += ((data % 1000000000000)/ 10000000000) % 10;

        abilities[tokenId].level  += 1;
        abilities[tokenId].points += calculate_exp(abilities[tokenId].p1,  
                                                   abilities[tokenId].p2, 
                                                   abilities[tokenId].p3, 
                                                   abilities[tokenId].p4, 
                                                   abilities[tokenId].p5, 
                                                   abilities[tokenId].p6);
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
