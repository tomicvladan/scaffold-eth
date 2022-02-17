import React, { useCallback, useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { Select, Button, Card, Col, Input, List, Menu, Row, Progress } from "antd";
import FText from "../../components/FText";
import { useContractReader } from "eth-hooks";
import { notification } from "antd";
import { ethers } from "ethers";
import * as helpers from "./../helpers";
import { uploadJsonToBee } from "./../SwarmUpload/BeeService";

// function TokenVoteView(props) {
//   const { index, token, onVote, canVote } = props;
//   return (
//     <Card size="large" hoverable>
//       <div style={{ display: "block", alignItems: "right" }}>
//         <div style={{ float: "left", textAlign: "center" }}>
//           <small>{index}.</small> &nbsp;&nbsp;&nbsp; <strong>{token.name}</strong> &nbsp;&nbsp;&nbsp; votes: {token.votes}
//         </div>

//         <div style={{ float: "right" }}>
//           {canVote ? (
//             <span style={{ /*textDecoration: "underline",*/ cursor: "pointer" }} onClick={e => onVote(token)}>
//               <FText>vote</FText>
//             </span>
//           ) : null}
//         </div>
//       </div>
//     </Card>
//   );
// }

export default function TeamView(props) {
  const [seconds, setSeconds] = useState(0);
  const [isActive, setIsActive] = useState(true);

  const [contract, setContract] = useState(null);
  const [tokenData, setTokenData] = useState({ name: "", links: [], parents: [], uri: "", posts: [] });
  const [avatarToken, setAvatarToken] = useState({ name: "", links: [], parents: [], uri: "", posts: [] });
  const [postText, setPostText] = useState("");
  //const [posts, setPosts] = useState([]);
  const [links, setLinks] = useState([]);
  const [parentLinks, setParentLinks] = useState([]);

  let { contractAddress, id } = useParams();

  const {
    yourDmBalance,
    dmCollections,
    localProvider,
    contractConfig,
    writeContracts,
    readContracts,
    userSigner,
    mainnetProvider,
    userProviderAndSigner,
    address,
    tx,
  } = props;

  useEffect(() => {
    let interval = null;
    if (isActive) {
      interval = setInterval(() => {
        setSeconds(seconds => seconds + 1);
      }, 15000);
    } else if (!isActive && seconds !== 0) {
      clearInterval(interval);
    }
    return () => clearInterval(interval);
  }, [seconds]);

  useEffect(() => {
    getDMNFTToken();
  }, [seconds]);
  useEffect(() => {}, [tokenData]);
  //useEffect(() => {}, [posts]);

  useEffect(() => {
    getDMNFTToken();
  }, [contract, id]);

  useEffect(() => {
    getDMCollectionContract(3);
  }, []);

  function getDMCollectionContract(contractIndex) {
    if (dmCollections === undefined) return null;
    const contracts = helpers.findPropertyInObject("contracts", contractConfig.deployedContracts);
    const teamsContract = new ethers.Contract(dmCollections[contractIndex], contracts.DMCollection.abi, userSigner);
    setContract(teamsContract);
  }
  const getDMNFTTokenInfo = useCallback(async () => {}, []);

  const getDMNFTToken = useCallback(async () => {
    if (contract == null || contract == undefined) return;

    const avatarBalance = await readContracts.Avatar.balanceOf(address);
    if (avatarBalance.toNumber() > 0) {
      const avatarTokenId = await readContracts.Avatar.tokenOfOwnerByIndex(address, 0);
      const avatarToken = await readContracts.Avatar.getAvatarInfo(avatarTokenId);
      //console.log("avatarToken", avatarToken);
      setAvatarToken(avatarToken);
    }

    const links = await helpers.makeCall("getLinks", contract, [id]);
    setLinks(links);

    var parentLinks = [];
    if (links != undefined && links.length > 0) {
      parentLinks = await helpers.makeCall("getLinks", contract, [links[0].tokenId]);
    }

    setParentLinks(parentLinks);
    var tokenInfo = await helpers.makeCall("tokenData", contract, [id]);
    var tokenUri = await helpers.makeCall("tokenURI", contract, [id]);
    var dataLocationCount = await helpers.makeCall("dataLocationCount", contract, [id]);

    //console.log("dataLocationCount", dataLocationCount);
    var locations = [];
    var posts = [];
    if (dataLocationCount != undefined) {
      var start = dataLocationCount.toNumber();
      var count = 10;
      for (var i = start - 1; i >= 0; i--) {
        count--;
        if (count == -1) break;
        try {
          console.log("dataLocationCount", start, i);
          var dataLocation = await helpers.makeCall("dataLocations", contract, [id, i]);
          locations.push(dataLocation);
          var url = helpers.downloadGateway + dataLocation.substring(2) + "/";
          var json = await (await fetch(url)).json();
          posts.push(json);
          //posts = json;
          console.log("posts", posts);
          //console.log("data", i, url, json);
        } catch (e) {
          console.log("error", e);
        }
      }
    }

    //var tokenAddressables = await helpers.makeCall("tokenAddressables", contract, [id]);

    try {
      var data = JSON.parse(tokenInfo);
      data.id = id.toString();
      data.tokenUri = tokenUri;
      data.name = ethers.utils.toUtf8String(data.n).replace(/[^\x01-\x7F]/g, "");
      data.uri = tokenUri;
      data.links = links;
      data.parents = parentLinks;
      data.locations = locations;
      data.posts = posts;
      console.log("tokenData", data);
      setTokenData(data);
    } catch (e) {
      console.log(e);
    }
  }, [contract]);

  async function addPostToToken(token) {
    notification.success({
      message: "Data",
      description: "Adding data to token",
      placement: "topRight",
    });
    // post to data to swarm get swarm hash

    var post = {
      title: "",
      text: postText,
      address: address,
      time: Date.now(),
      avatarId: avatarToken.id,
      avatarName: avatarToken.name,
      /*name: tokenData.name,*/
      id: tokenData.id,
      uri: tokenData.uri,
      contract: contract.address,
    };
    tokenData.posts.push(post);
    console.log("post text", post);
    const swarmHash = await uploadJsonToBee(post, "post.json");
    console.log("swarmHash", swarmHash);
    const result = await helpers.makeCall("addDataLocation", contract, [id, "0x" + swarmHash]); // make tx
    //console.log("result", result);
  }

  //console.log("posts", tokenData.posts);
  tokenData.posts.map((d, i) => {console.log(d.text)});
  return (
    <div style={{ maxWidth: 600, margin: "auto", marginTop: 5, paddingBottom: 25, lineHeight: 1.5 }}>
      <Card title={<h1>{tokenData.name}</h1>}>
        <Input
          style={{ width: "80%" }}
          min={0}
          size="large"
          value={postText}
          placeholder={"What are you creating, " + avatarToken.name + " ?"}
          onChange={e => {
            try {
              setPostText(e.target.value);
            } catch (e) {
              console.log(e);
            }
          }}
        />
        <Button
          onClick={e => {
            addPostToToken();
          }}
        >
          Post
        </Button>
        <br />
      </Card>

      {tokenData.posts.map((d, i) => 
      <div>
        <div style={{textAlign:"right"}}><small>{d.avatarName}</small></div>
        <div style={{textAlign:"center"}}>{d.title}</div>
        <div style={{textAlign:"left"}}>{d.text}</div>
      </div>)}

      {/* {tokenData.posts.map((post, i) => {
          <p key={"post_" + i}>
            <span>{post.id}</span>
            <span>{post.avatarName}</span>
            <span>{post.text}</span> hhh
          </p>;
        })} */}

      <small>
        Team Members: {tokenData.links.length} Parents: {tokenData.parents.length}
      </small>

      {/* {tokens.map((token, index) => {
        return <TokenVoteView key={index} index={index + 1} token={token} onVote={voteForToken} canVote={canVote} />;
      })} */}
    </div>
  );
}
